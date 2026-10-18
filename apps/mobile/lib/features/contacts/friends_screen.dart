import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, this.query});
  final String? query;
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final search = TextEditingController();
  List<dynamic> users = [], requests = [];
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    search.text = widget.query ?? '';
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await ref.read(clientProvider).get('/friends/requests');
      if (mounted) setState(() => requests = r);
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    }
  }

  Future<void> find() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref
          .read(clientProvider)
          .get('/users/search?q=${Uri.encodeComponent(search.text.trim())}');
      if (mounted) setState(() => users = r);
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(Future<dynamic> Function() work) async {
    try {
      await work();
      await load();
    } catch (e) {
      if (mounted) setState(() => error = tr(context, 'networkError'));
    }
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: tr(c, 'newFriends'),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => context.pop(),
    ),
    child: ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              QChatTextInput(controller: search, hint: 'QChat ID'),
              const SizedBox(height: 12),
              QChatButton(
                tr(c, busy ? 'loading' : 'search'),
                onTap: busy ? null : find,
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              style: const TextStyle(color: QChatColors.danger),
            ),
          ),
        for (final u in users)
          QChatListTile(
            title: u['nickname'],
            subtitle: u['qchatId'],
            leading: QChatAvatar(u['nickname']),
            trailing: QChatButton(
              tr(c, 'add'),
              onTap: () => action(() async {
                await ref.read(clientProvider).post('/friends/requests', {
                  'recipientId': u['id'],
                });
                if (mounted) setState(() => users = []);
              }),
            ),
          ),
        const SizedBox(height: 24),
        for (final r in requests)
          QChatListTile(
            title: r['sender']['nickname'],
            subtitle: r['sender']['qchatId'],
            leading: QChatAvatar(r['sender']['nickname']),
            onTap: () => qchatSheet(c, [
              (
                tr(c, 'accept'),
                () => action(
                  () => ref
                      .read(clientProvider)
                      .dio
                      .patch(
                        '/friends/requests/${r['id']}',
                        data: {'accept': true},
                      ),
                ),
              ),
              (
                tr(c, 'reject'),
                () => action(
                  () => ref
                      .read(clientProvider)
                      .dio
                      .patch(
                        '/friends/requests/${r['id']}',
                        data: {'accept': false},
                      ),
                ),
              ),
            ]),
          ),
        if (requests.isEmpty && users.isEmpty)
          QChatEmptyState(tr(c, 'emptyContacts')),
      ],
    ),
  );
}
