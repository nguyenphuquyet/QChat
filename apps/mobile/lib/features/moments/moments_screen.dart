import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});
  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  late Future<dynamic> feed;
  StreamSubscription<void>? updates;
  final text = TextEditingController();
  bool composing = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
    updates = ref.read(clientProvider).changes.stream.listen((_) {
      if (mounted) setState(load);
    });
  }

  void load() {
    feed = ref.read(clientProvider).get('/moments');
  }

  @override
  void dispose() {
    updates?.cancel();
    text.dispose();
    super.dispose();
  }

  Future<void> post() async {
    setState(() => busy = true);
    try {
      await ref.read(clientProvider).post('/moments', {
        'text': text.text,
        'privacy': 'FRIENDS',
      });
      text.clear();
      if (mounted) {
        setState(() {
          composing = false;
          load();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: tr(c, 'moments'),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => context.pop(),
    ),
    trailing: QChatIconButton(
      'plus',
      label: tr(c, 'post'),
      onTap: () => setState(() => composing = !composing),
    ),
    child: Column(
      children: [
        if (composing)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                QChatTextInput(
                  controller: text,
                  hint: tr(c, 'writeMoment'),
                  lines: 4,
                ),
                const SizedBox(height: 8),
                QChatButton(
                  tr(c, busy ? 'loading' : 'post'),
                  onTap: busy ? null : post,
                ),
              ],
            ),
          ),
        if (error != null)
          Text(error!, style: const TextStyle(color: QChatColors.danger)),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: feed,
            builder: (c, s) {
              if (s.hasError && !ref.read(clientProvider).offline.value) {
                return QChatError(error: s.error!, retry: () => setState(load));
              }
              final posts = s.data as List? ?? [];
              return ListView(
                children: [
                  Container(
                    height: 190,
                    color: const Color(0xff2f5345),
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      tr(c, 'moments'),
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: QChatEmptyState(tr(c, 'emptyMoments')),
                    ),
                  for (final p in posts)
                    Container(
                      color: surface(c),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QChatAvatar(p['author']['nickname'], size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['author']['nickname'],
                                  style: const TextStyle(
                                    color: Color(0xff546d91),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(p['text']),
                                const SizedBox(height: 12),
                                for (final media in p['media'])
                                  QChatListTile(
                                    title: tr(c, 'image'),
                                    onTap: () => context.push(
                                      '/media/${media['mediaId']}',
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Text(
                                      p['createdAt'].toString().substring(
                                        0,
                                        10,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: QChatColors.muted,
                                      ),
                                    ),
                                    const Spacer(),
                                    QChatButton(
                                      '♡ ${(p['likes'] as List).length}',
                                      secondary: true,
                                      onTap: () async {
                                        try {
                                          await ref
                                              .read(clientProvider)
                                              .post(
                                                '/moments/${p['id']}/likes',
                                                {},
                                              );
                                          if (mounted) setState(load);
                                        } catch (e) {
                                          if (mounted) {
                                            setState(
                                              () =>
                                                  error = tr(c, 'networkError'),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                for (final comment in p['comments'])
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      comment['text'],
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
