import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/design_system/reference_widgets.dart';
import '../../core/localization/strings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Widget entry(BuildContext c, String key, {String? route}) =>
      tr(c, key).toLowerCase().contains(search.text.toLowerCase())
      ? MenuRow(key, onTap: () => c.push(route ?? '/settings/$key'))
      : const SizedBox.shrink();
  @override
  Widget build(BuildContext c) => QChatPage(
    edgeToEdge: true,
    title: tr(c, 'settings'),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => c.pop(),
    ),
    child: ListView(
      children: [
        QChatSearchBar(controller: search, onChanged: (_) => setState(() {})),
        const SectionLabel('account'),
        entry(c, 'profile', route: '/profile'),
        entry(c, 'security', route: '/sessions'),
        entry(c, 'permissions'),
        const SectionLabel('general'),
        entry(c, 'notifications'),
        entry(c, 'display'),
        entry(c, 'friendPermissions'),
        entry(c, 'storage'),
        entry(c, 'more', route: '/about'),
        const SectionLabel('features'),
        entry(c, 'conversations'),
        entry(c, 'calls'),
        sectionGap,
        QChatListTile(
          title: tr(c, 'logout'),
          onTap: () async {
            try {
              await ref.read(clientProvider).logout();
              if (c.mounted) c.go('/login');
            } catch (_) {
              if (c.mounted) qchatSheet(c, [(tr(c, 'networkError'), () {})]);
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class SettingsDetailScreen extends ConsumerStatefulWidget {
  const SettingsDetailScreen({super.key, required this.kind});
  final String kind;
  @override
  ConsumerState<SettingsDetailScreen> createState() =>
      _SettingsDetailScreenState();
}

class _SettingsDetailScreenState extends ConsumerState<SettingsDetailScreen> {
  late final Future<dynamic> user = ref.read(clientProvider).get('/users/me');
  @override
  Widget build(BuildContext c) {
    final prefs = ref.watch(preferencesProvider);
    return QChatPage(
      title: tr(c, widget.kind),
      leading: QChatIconButton(
        'back',
        label: tr(c, 'back'),
        onTap: () => c.pop(),
      ),
      child: widget.kind == 'display'
          ? ListView(
              children: [
                sectionGap,
                MenuRow(
                  'language',
                  value: prefs.locale,
                  onTap: () => qchatSheet(c, [
                    (
                      'Tiếng Việt',
                      () =>
                          ref.read(preferencesProvider.notifier).language('vi'),
                    ),
                    (
                      'English',
                      () =>
                          ref.read(preferencesProvider.notifier).language('en'),
                    ),
                    (
                      '简体中文',
                      () =>
                          ref.read(preferencesProvider.notifier).language('zh'),
                    ),
                  ]),
                ),
                MenuRow(
                  'appearance',
                  value: prefs.dark ? 'Tối' : 'Sáng',
                  onTap: () => ref
                      .read(preferencesProvider.notifier)
                      .appearance(!prefs.dark),
                ),
              ],
            )
          : ['notifications', 'friendPermissions'].contains(widget.kind)
          ? FutureBuilder<dynamic>(
              future: user,
              builder: (c, s) {
                if (s.hasError) return QChatEmptyState(tr(c, 'networkError'));
                if (!s.hasData) return const QChatLoading();
                final field = widget.kind == 'notifications'
                    ? 'previewPush'
                    : 'allowRequests';
                return ListView(
                  children: [
                    sectionGap,
                    MenuRow(
                      widget.kind == 'notifications'
                          ? 'previewPush'
                          : 'allowRequests',
                      value: s.data[field] == true ? '✓' : '—',
                      onTap: () async {
                        try {
                          final value = s.data[field] != true;
                          await ref
                              .read(clientProvider)
                              .dio
                              .patch('/users/me', data: {field: value});
                          if (mounted) setState(() => s.data[field] = value);
                        } catch (_) {
                          if (c.mounted) {
                            qchatSheet(c, [(tr(c, 'networkError'), () {})]);
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            )
          : QChatEmptyState(tr(c, 'notAvailable'), icon: 'settings'),
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
