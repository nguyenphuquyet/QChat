import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    return QChatPage(
      title: tr(c, 'settings'),
      leading: QChatIconButton(
        'back',
        label: tr(c, 'back'),
        onTap: () => c.pop(),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 12),
          QChatListTile(
            title: tr(c, 'profile'),
            onTap: () => c.push('/profile'),
          ),
          QChatListTile(
            title: tr(c, 'sessions'),
            onTap: () => c.push('/sessions'),
          ),
          const SizedBox(height: 12),
          QChatListTile(
            title: tr(c, 'language'),
            subtitle: prefs.locale,
            onTap: () => qchatSheet(c, [
              (
                'Tiếng Việt',
                () => ref.read(preferencesProvider.notifier).language('vi'),
              ),
              (
                'English',
                () => ref.read(preferencesProvider.notifier).language('en'),
              ),
              (
                '简体中文',
                () => ref.read(preferencesProvider.notifier).language('zh'),
              ),
            ]),
          ),
          QChatListTile(
            title: tr(c, 'appearance'),
            trailing: Text(
              prefs.dark ? '✓' : '○',
              style: const TextStyle(color: QChatColors.green, fontSize: 24),
            ),
            onTap: () =>
                ref.read(preferencesProvider.notifier).appearance(!prefs.dark),
          ),
          const SizedBox(height: 12),
          QChatListTile(
            title: tr(c, 'about'),
            subtitle: 'QChat 0.1.0',
            onTap: () => c.push('/about'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: QChatButton(
              tr(c, 'logout'),
              secondary: true,
              onTap: () async {
                try {
                  await ref.read(clientProvider).logout();
                  if (c.mounted) c.go('/login');
                } catch (e) {
                  if (c.mounted) {
                    qchatSheet(c, [(tr(c, 'networkError'), () {})]);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DataListScreen extends ConsumerStatefulWidget {
  const DataListScreen({super.key, required this.kind});
  final String kind;
  @override
  ConsumerState<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends ConsumerState<DataListScreen> {
  late Future<dynamic> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    data = ref
        .read(clientProvider)
        .get(
          widget.kind == 'sessions' ? '/auth/sessions' : '/favorites',
          cached: false,
        );
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: tr(c, widget.kind),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => c.pop(),
    ),
    child: FutureBuilder<dynamic>(
      future: data,
      builder: (c, s) {
        if (s.hasError) {
          return QChatError(error: s.error!, retry: () => setState(load));
        }
        if (!s.hasData) return const QChatLoading();
        final items = s.data as List;
        if (items.isEmpty) return QChatEmptyState(tr(c, 'noItems'));
        return ListView(
          children: [
            for (final item in items)
              QChatListTile(
                title: widget.kind == 'sessions'
                    ? item['deviceName']
                    : item['text'],
                subtitle: item['createdAt'],
                onTap: widget.kind == 'sessions'
                    ? () => qchatSheet(c, [
                        (
                          tr(c, 'logout'),
                          () async {
                            await ref
                                .read(clientProvider)
                                .dio
                                .delete('/auth/sessions/${item['id']}');
                            if (mounted) setState(load);
                          },
                        ),
                      ])
                    : null,
              ),
          ],
        );
      },
    ),
  );
}
