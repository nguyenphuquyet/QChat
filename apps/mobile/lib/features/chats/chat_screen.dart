import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';
import 'message_status.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final input = TextEditingController(), scroll = ScrollController();
  List<Map<String, dynamic>> messages = [];
  StreamSubscription<void>? updates;
  StreamSubscription<void>? messageUpdates;
  List<dynamic> members = [];
  int readSequence = 0;
  String title = 'QChat';
  String? error, reply;
  bool loading = true, emoji = false, uploading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scroll.addListener(() {
      if (scroll.hasClients &&
          scroll.position.extentAfter < 20 &&
          messages.any((m) => (m['sequence'] as int? ?? 0) > readSequence)) {
        load();
      }
    });
    load();
    updates = ref.read(clientProvider).changes.stream.listen((_) {
      if (mounted) load();
    });
    messageUpdates = ref.read(clientProvider).messageChanges.stream.listen((_) {
      if (!mounted) return;
      final nearEnd = !scroll.hasClients || scroll.position.extentAfter < 100;
      final previousCount = messages.length;
      setState(() {
        messages = ref
            .read(clientProvider)
            .visibleMessages(widget.id, messages);
        loading = false;
      });
      if (nearEnd ||
          (messages.length > previousCount &&
              messages.last['pending'] == true)) {
        scrollToEnd();
      }
    });
  }

  @override
  void dispose() {
    updates?.cancel();
    messageUpdates?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  bool fetching = false;
  bool reload = false;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  void scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  Future<void> load() async {
    if (fetching) {
      reload = true;
      return;
    }
    fetching = true;
    final nearEnd =
        !scroll.hasClients ||
        scroll.position.maxScrollExtent - scroll.offset < 100;
    try {
      final client = ref.read(clientProvider);
      final rows = await client.messages(widget.id);
      final c = await client.get('/conversations/${widget.id}');
      final others = (c['members'] as List).where(
        (m) => m['userId'] != client.userId,
      );
      if (mounted) {
        setState(() {
          messages = client.visibleMessages(widget.id, rows);
          members = c['members'];
          title = c['kind'] == 'GROUP'
              ? c['title']
              : others.isEmpty
              ? 'QChat'
              : others.first['user']['nickname'];
          error = null;
        });
      }
      final sent = rows.where((m) => m['pending'] != true);
      if (sent.isNotEmpty &&
          nearEnd &&
          mounted &&
          (WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) &&
          (ModalRoute.of(context)?.isCurrent ?? false) &&
          (sent.last['sequence'] as int) > readSequence) {
        unawaited(
          client
              .post('/conversations/${widget.id}/read', {
                'sequence': sent.last['sequence'],
              })
              .then((_) {
                readSequence = sent.last['sequence'];
              })
              .catchError((_) {}),
        );
      }
      if (nearEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    } finally {
      fetching = false;
      if (mounted) setState(() => loading = false);
      if (reload && mounted) {
        reload = false;
        unawaited(load());
      }
    }
  }

  Future<void> send() async {
    if (input.text.trim().isEmpty) return;
    final text = input.text;
    input.clear();
    try {
      await ref.read(clientProvider).send(widget.id, text, replyToId: reply);
      if (mounted) setState(() => reply = null);
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    }
  }

  Future<void> attach() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'mp4',
        'mp3',
        'pdf',
      ],
    );
    if (result == null) return;
    final file = result;
    final bytes = await file.readAsBytes();

    const mime = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'pdf': 'application/pdf',
    };
    final type = mime[file.extension];
    if (type == null) return;
    setState(() => uploading = true);
    try {
      final client = ref.read(clientProvider);
      final intent = await client.post('/media/upload-intent', {
        'name': file.name,
        'size': bytes.length,
        'mime': type,
      });
      await Dio().put(
        intent['url'],
        data: bytes,
        options: Options(headers: {'Content-Type': type}),
      );
      await client.post('/media/complete', {'mediaId': intent['id']});
      await client.send(
        widget.id,
        file.name,
        kind: type.startsWith('image')
            ? 'IMAGE'
            : type.startsWith('video')
            ? 'VIDEO'
            : type.startsWith('audio')
            ? 'AUDIO'
            : 'FILE',
        mediaId: intent['id'],
      );
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void menu(Map<String, dynamic> m) {
    qchatSheet(context, [
      (
        tr(context, 'copy'),
        () => Clipboard.setData(ClipboardData(text: m['text'] ?? '')),
      ),
      (tr(context, 'reply'), () => setState(() => reply = m['id'])),
      if (m['pending'] != true) ...[
        (
          tr(context, 'favorites'),
          () => operation(
            () => ref
                .read(clientProvider)
                .dio
                .patch(
                  '/messages/${m['id']}/favorite',
                  data: {'favorite': true},
                ),
          ),
        ),
        (
          tr(context, 'delete'),
          () => operation(
            () => ref.read(clientProvider).dio.delete('/messages/${m['id']}'),
          ),
        ),
        if (m['senderId'] == ref.read(clientProvider).userId)
          (
            tr(context, 'recall'),
            () => operation(
              () => ref
                  .read(clientProvider)
                  .post('/messages/${m['id']}/recall', {}),
            ),
          ),
      ],
    ]);
  }

  Future<void> operation(Future<dynamic> Function() fn) async {
    try {
      await fn();
      await ref.read(clientProvider).local!.cache('messages:${widget.id}', []);
      await ref.read(clientProvider).local!.cache('cursor:${widget.id}', 0);
      ref
          .read(clientProvider)
          .confirmed
          .removeWhere((_, m) => m['conversationId'] == widget.id);
      await load();
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    }
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: title,
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => context.go('/home'),
    ),
    trailing: QChatIconButton(
      'more',
      label: tr(c, 'settings'),
      onTap: () => qchatSheet(c, [
        (tr(c, 'call'), () => context.push('/call/${widget.id}?video=false')),
        (
          tr(c, 'videoCall'),
          () => context.push('/call/${widget.id}?video=true'),
        ),
        (
          tr(c, 'mute'),
          () => operation(
            () => ref
                .read(clientProvider)
                .dio
                .patch(
                  '/conversations/${widget.id}/state',
                  data: {'muted': true},
                ),
          ),
        ),
      ]),
    ),
    child: Column(
      children: [
        if (error != null)
          GestureDetector(
            onTap: load,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                error!,
                style: const TextStyle(color: QChatColors.danger, fontSize: 12),
              ),
            ),
          ),
        Expanded(
          child: loading
              ? const QChatLoading()
              : messages.isEmpty
              ? QChatEmptyState(tr(c, 'emptyChats'))
              : ListView.builder(
                  controller: scroll,
                  itemCount: messages.length,
                  itemBuilder: (c, i) {
                    final m = messages[i],
                        mine = m['senderId'] == ref.read(clientProvider).userId;
                    return Column(
                      children: [
                        if (i == 0 || i % 15 == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              (m['createdAt'] ?? '')
                                  .toString()
                                  .replaceFirst('T', ' ')
                                  .substring(0, 16),
                              style: const TextStyle(
                                fontSize: 11,
                                color: QChatColors.muted,
                              ),
                            ),
                          ),
                        QChatChatBubble(
                          mine: mine,
                          name: mine ? 'Q' : title,
                          onLongPress: () => menu(m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m['replyToId'] != null)
                                Text(
                                  '↳ ${tr(c, 'reply')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: QChatColors.muted,
                                  ),
                                ),
                              if (m['mediaId'] != null)
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/media/${m['mediaId']}'),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: QChatIcon(
                                      m['kind'] == 'IMAGE' ? 'image' : 'file',
                                      size: 40,
                                    ),
                                  ),
                                ),
                              Text(
                                m['recalledAt'] != null
                                    ? tr(c, 'recalled')
                                    : m['text'] ?? '',
                              ),
                            ],
                          ),
                        ),
                        if (mine && m['recalledAt'] == null)
                          MessageStatus(
                            status: ref
                                .read(clientProvider)
                                .messageStatus(m, members),
                            onRetry: () => ref.read(clientProvider).flush(),
                          ),
                      ],
                    );
                  },
                ),
        ),
        if (reply != null)
          QChatListTile(
            title: tr(c, 'reply'),
            trailing: QChatButton(
              tr(c, 'cancel'),
              onTap: () => setState(() => reply = null),
            ),
          ),
        Container(
          color: surface(c),
          padding: EdgeInsets.fromLTRB(
            8,
            7,
            8,
            7 + MediaQuery.viewInsetsOf(c).bottom,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: QChatTextInput(
                  controller: input,
                  hint: tr(c, 'message'),
                  lines: 4,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              QChatIconButton(
                'emoji',
                label: 'Emoji',
                onTap: () => setState(() => emoji = !emoji),
              ),
              if (input.text.trim().isEmpty)
                QChatIconButton(
                  'plus',
                  label: tr(c, 'file'),
                  onTap: uploading ? () {} : attach,
                )
              else
                QChatButton(tr(c, 'send'), onTap: send),
            ],
          ),
        ),
        if (uploading) Text(tr(c, 'loading')),
        if (emoji)
          Container(
            color: surface(c),
            height: 160,
            child: GridView.count(
              crossAxisCount: 8,
              children: [
                for (final e in [
                  '😀',
                  '😊',
                  '😂',
                  '🥰',
                  '😍',
                  '🤔',
                  '😢',
                  '😎',
                  '👍',
                  '👏',
                  '🙏',
                  '💚',
                  '❤️',
                  '🎉',
                  '🌻',
                  '☕',
                ])
                  GestureDetector(
                    onTap: () {
                      input.text += e;
                      setState(() {});
                    },
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
