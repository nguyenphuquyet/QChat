import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int index = 0;
  final search = TextEditingController();
  late Future<dynamic> data;
  StreamSubscription<void>? updates;
  @override
  void initState() {
    super.initState();
    load();
    updates = ref.read(clientProvider).changes.stream.listen((_) {
      if (mounted && index == 0) setState(load);
    });
  }

  void load() {
    final client = ref.read(clientProvider);
    data = client.get(
      index == 0
          ? '/conversations'
          : index == 1
          ? '/friends'
          : '/users/me',
    );
  }

  @override
  void dispose() {
    updates?.cancel();
    search.dispose();
    super.dispose();
  }

  String conversationName(Map c) {
    if (c['kind'] == 'GROUP') return c['title'];
    final others = (c['members'] as List).where(
      (m) => m['userId'] != ref.read(clientProvider).userId,
    );
    return others.isEmpty ? 'QChat' : others.first['user']['nickname'];
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: index == 0
        ? 'QChat'
        : tr(c, ['chats', 'contacts', 'discover', 'me'][index]),
    trailing: index < 2
        ? QChatIconButton(
            'plus',
            label: tr(c, 'add'),
            onTap: () => qchatSheet(c, [
              (tr(c, 'add'), () => c.push('/friends')),
              (tr(c, 'newGroup'), () => c.push('/groups/new')),
            ]),
          )
        : null,
    bottom: QChatBottomNavigation(
      index: index,
      onChanged: (v) => setState(() {
        index = v;
        search.clear();
        load();
      }),
    ),
    child: index == 2
        ? ListView(
            children: [
              const SizedBox(height: 12),
              QChatListTile(
                title: tr(c, 'moments'),
                leading: const QChatIcon('discover', color: QChatColors.green),
                onTap: () => c.push('/moments'),
              ),
              const SizedBox(height: 12),
              QChatListTile(
                title: tr(c, 'scan'),
                leading: const QChatIcon('scan', color: Color(0xff4f91c6)),
                onTap: () => c.push('/scan'),
              ),
            ],
          )
        : FutureBuilder<dynamic>(
            future: data,
            builder: (c, s) {
              if (s.hasError) {
                return QChatError(error: s.error!, retry: () => setState(load));
              }
              if (!s.hasData) return const QChatLoading();
              if (index == 3) {
                final u = s.data as Map;
                return ListView(
                  children: [
                    const SizedBox(height: 12),
                    QChatListTile(
                      title: u['nickname'],
                      subtitle: 'QChat ID: ${u['qchatId']}',
                      leading: QChatAvatar(u['nickname'], size: 64),
                      trailing: const QChatIcon('scan'),
                      onTap: () => c.push('/profile'),
                    ),
                    const SizedBox(height: 12),
                    QChatListTile(
                      title: tr(c, 'qr'),
                      leading: const QChatIcon('scan'),
                      onTap: () => c.push('/qr'),
                    ),
                    QChatListTile(
                      title: tr(c, 'moments'),
                      leading: const QChatIcon('discover'),
                      onTap: () => c.push('/moments'),
                    ),
                    QChatListTile(
                      title: tr(c, 'favorites'),
                      leading: const QChatIcon('file'),
                      onTap: () => c.push('/favorites'),
                    ),
                    const SizedBox(height: 12),
                    QChatListTile(
                      title: tr(c, 'settings'),
                      leading: const QChatIcon('settings'),
                      onTap: () => c.push('/settings'),
                    ),
                  ],
                );
              }
              final items = (s.data as List).where((item) {
                final name = index == 0
                    ? conversationName(item)
                    : item['friend']['nickname'];
                return name.toString().toLowerCase().contains(
                  search.text.toLowerCase(),
                );
              }).toList();
              return Column(
                children: [
                  QChatSearchBar(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (index == 1)
                    QChatListTile(
                      title: tr(c, 'newFriends'),
                      leading: Container(
                        color: const Color(0xfff2a14a),
                        padding: const EdgeInsets.all(8),
                        child: const QChatIcon('contacts', color: Colors.white),
                      ),
                      onTap: () => c.push('/friends'),
                    ),
                  Expanded(
                    child: items.isEmpty
                        ? QChatEmptyState(
                            tr(c, index == 0 ? 'emptyChats' : 'emptyContacts'),
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (c, i) {
                              final item = items[i];
                              if (index == 1) {
                                final friend = item['friend'];
                                return QChatListTile(
                                  title: item['remark'].toString().isEmpty
                                      ? friend['nickname']
                                      : item['remark'],
                                  subtitle: friend['qchatId'],
                                  leading: QChatAvatar(friend['nickname']),
                                  onTap: () async {
                                    try {
                                      final conversation = await ref
                                          .read(clientProvider)
                                          .post('/conversations', {
                                            'memberIds': [friend['id']],
                                          });
                                      if (c.mounted) {
                                        c.push(
                                          '/chat/${conversation['id']}',
                                        );
                                      }
                                    } catch (e) {
                                      if (c.mounted) {
                                        qchatSheet(c, [
                                          (
                                            tr(c, 'networkError'),
                                            () => setState(load),
                                          ),
                                        ]);
                                      }
                                    }
                                  },
                                );
                              }
                              final name = conversationName(item);
                              final messages = item['messages'] as List;
                              final mine = (item['members'] as List).firstWhere(
                                (m) =>
                                    m['userId'] ==
                                    ref.read(clientProvider).userId,
                              );
                              return QChatConversationTile(
                                name: name,
                                preview: messages.isEmpty
                                    ? ''
                                    : messages.first['recalledAt'] != null
                                    ? tr(c, 'recalled')
                                    : messages.first['text'].toString().isEmpty
                                    ? '[${messages.first['kind']}]'
                                    : messages.first['text'],
                                unread:
                                    (item['sequence'] as int) -
                                    (mine['readSequence'] as int),
                                onTap: () =>
                                    c.push('/chat/${item['id']}'),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
  );
}

