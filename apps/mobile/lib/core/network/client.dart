import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';
import '../storage/database.dart';

const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000/api',
);
const realtimeUrl = String.fromEnvironment(
  'REALTIME_URL',
  defaultValue: 'http://localhost:3001',
);

class QChatClient {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final storage = const FlutterSecureStorage();
  final changes = StreamController<void>.broadcast();
  String? userId, token;
  io.Socket? socket;
  LocalDatabase? local;
  Future<void>? refreshing;
  bool flushing = false;
  bool stopping = false;
  QChatClient() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (token != null) o.headers['Authorization'] = 'Bearer $token';
          h.next(o);
        },
        onError: (e, h) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.extra['retry'] != true &&
              !e.requestOptions.path.startsWith('/auth/')) {
            try {
              await refresh();
              e.requestOptions.extra['retry'] = true;
              e.requestOptions.headers['Authorization'] = 'Bearer $token';
              h.resolve(await dio.fetch(e.requestOptions));
              return;
            } catch (_) {}
          }
          h.next(e);
        },
      ),
    );
  }
  Future<bool> restore() async {
    userId = await storage.read(key: 'userId');
    if (userId == null) return false;
    local = LocalDatabase(userId!);
    try {
      await refresh();
      connect();
    } catch (_) {
      /* Keep account-scoped cache available offline. */
    }
    return true;
  }

  Future<void> login(Map<String, dynamic> data, {bool register = false}) async {
    final response = await dio.post(
      '/auth/${register ? 'register' : 'login'}',
      data: data,
    );
    await save(Map<String, dynamic>.from(response.data));
    local = LocalDatabase(userId!);
    connect();
  }

  Future<void> save(Map<String, dynamic> data) async {
    token = data['accessToken'];
    userId = data['userId'];
    await storage.write(key: 'refreshToken', value: data['refreshToken']);
    await storage.write(key: 'userId', value: userId);
  }

  Future<void> refresh() async {
    if (refreshing != null) return refreshing;
    refreshing = _refresh();
    try {
      await refreshing;
    } finally {
      refreshing = null;
    }
  }

  Future<void> _refresh() async {
    final refresh = await storage.read(key: 'refreshToken');
    if (refresh == null) throw StateError('Session expired');
    final r = await Dio().post(
      '$apiUrl/auth/refresh',
      data: {'refreshToken': refresh},
    );
    await save(Map<String, dynamic>.from(r.data));
  }

  void connect() {
    stopping = true;
    socket?.dispose();
    stopping = false;
    socket = io.io(
      realtimeUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .build(),
    );
    socket!.onConnect((_) {
      flush();
      changes.add(null);
    });
    socket!.on('message:new', (_) => changes.add(null));
    socket!.on('message:recall', (event) async {
      final key = 'messages:${event['conversationId']}';
      final rows = await local?.read(key);
      if (rows is List) {
        for (final row in rows) {
          if (row['id'] == event['id']) {
            row['text'] = '';
            row['mediaId'] = null;
            row['recalledAt'] = DateTime.now().toIso8601String();
          }
        }
        await local?.cache(key, rows);
      }
      changes.add(null);
    });
    socket!.onDisconnect((_) async {
      if (stopping) return;
      try {
        await refresh();
        socket!.auth = {'token': token};
        socket!.connect();
      } catch (_) {}
    });
    socket!.connect();
  }

  Future<dynamic> get(String path, {bool cached = true}) async {
    try {
      final data = (await dio.get(path)).data;
      if (cached) await local?.cache(path, data);
      return data;
    } catch (e) {
      if (cached) {
        final data = await local?.read(path);
        if (data != null) return data;
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, Object data) async =>
      (await dio.post(path, data: data)).data;
  Future<void> send(
    String conversation,
    String text, {
    String kind = 'TEXT',
    String? mediaId,
    String? replyToId,
  }) async {
    final payload = {
      'conversationId': conversation,
      'clientId': const Uuid().v4(),
      'kind': kind,
      'text': text,
      'mediaId': ?mediaId,
      'replyToId': ?replyToId,
    };
    await local!.enqueue(payload);
    changes.add(null);
    await flush();
  }

  Future<void> flush() async {
    if (flushing || local == null) return;
    flushing = true;
    try {
      for (final p in await local!.pending()) {
        try {
          await post(
            '/conversations/${p['conversationId']}/messages',
            {...p}..remove('conversationId'),
          );
          await local!.remove(p['clientId']);
        } catch (_) {
          break;
        }
      }
    } finally {
      flushing = false;
      changes.add(null);
    }
  }

  Future<List<Map<String, dynamic>>> messages(String id) async {
    final key = 'messages:$id';
    final old = List<Map<String, dynamic>>.from(
      (await local!.read(key) ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
    int cursor = old.fold<int>(
      0,
      (n, m) => (m['sequence'] as int) > n ? m['sequence'] : n,
    );
    try {
      while (true) {
        final batch = List<Map<String, dynamic>>.from(
          (await get(
            '/conversations/$id/messages?after=$cursor',
            cached: false,
          )).map((e) => Map<String, dynamic>.from(e)),
        );
        for (final m in batch) {
          old.removeWhere((x) => x['id'] == m['id']);
          old.add(m);
          cursor = m['sequence'];
        }
        if (batch.length < 50) break;
      }
      await local!.cache(key, old);
    } catch (_) {
      if (old.isEmpty) rethrow;
    }
    final pending = (await local!.pending())
        .where((m) => m['conversationId'] == id)
        .map(
          (m) => {
            ...m,
            'id': m['clientId'],
            'senderId': userId,
            'pending': true,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
    return [...old, ...pending];
  }

  Future<void> logout() async {
    await post('/auth/logout', {});
    stopping = true;
    socket?.dispose();
    socket = null;
    await local?.clear();
    await local?.close();
    local = null;
    await storage.deleteAll();
    token = null;
    userId = null;
  }
}
