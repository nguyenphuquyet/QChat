import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';
import '../../core/design_system/reference_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.qr = false});
  final bool qr;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final name = TextEditingController(), bio = TextEditingController();
  late Future<dynamic> profile;
  StreamSubscription<void>? updates;
  bool initialized = false;
  String? error;
  Future<void> edit(String field, String label, String initial) async {
    final controller = TextEditingController(text: initial);
    bool saving = false;
    String? failure;
    final route = CupertinoPageRoute<void>(
      builder: (c) => StatefulBuilder(
        builder: (c, update) => QChatPage(
          title: tr(c, label),
          leading: QChatIconButton(
            'back',
            label: tr(c, 'back'),
            onTap: () => Navigator.pop(c),
          ),
          trailing: GestureDetector(
            onTap: saving
                ? null
                : () async {
                    update(() => saving = true);
                    try {
                      await ref
                          .read(clientProvider)
                          .dio
                          .patch(
                            '/users/me',
                            data: {field: controller.text.trim()},
                          );
                      if (c.mounted) Navigator.pop(c);
                      if (mounted) {
                        setState(
                          () => profile = ref
                              .read(clientProvider)
                              .get('/users/me'),
                        );
                      }
                    } catch (_) {
                      if (c.mounted) {
                        update(() {
                          saving = false;
                          failure = tr(c, 'networkError');
                        });
                      }
                    }
                  },
            child: Center(
              child: Text(
                tr(c, saving ? 'loading' : 'save'),
                style: const TextStyle(color: QChatColors.green),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                QChatTextInput(
                  controller: controller,
                  hint: tr(c, label),
                  lines: field == 'bio' ? 3 : 1,
                ),
                if (failure != null) Text(failure!),
              ],
            ),
          ),
        ),
      ),
    );
    await Navigator.of(context).push<void>(route);
    await route.completed;
    controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    profile = ref.read(clientProvider).get('/users/me');
    updates = ref.read(clientProvider).changes.stream.listen((_) {
      if (mounted) {
        setState(() => profile = ref.read(clientProvider).get('/users/me'));
      }
    });
  }

  @override
  void dispose() {
    updates?.cancel();
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: tr(c, widget.qr ? 'qr' : 'profile'),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => c.pop(),
    ),
    child: FutureBuilder<dynamic>(
      future: profile,
      builder: (c, s) {
        if (s.hasError) {
          return QChatError(
            error: s.error!,
            retry: () => setState(
              () => profile = ref.read(clientProvider).get('/users/me'),
            ),
          );
        }
        if (!s.hasData) return const QChatLoading();
        final u = s.data;
        if (!initialized) {
          name.text = u['nickname'];
          bio.text = u['bio'];
          initialized = true;
        }
        if (widget.qr) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QChatAvatar(u['nickname'], size: 64),
                const SizedBox(height: 16),
                Text(u['nickname']),
                const SizedBox(height: 24),
                QrImageView(
                  data: 'qchat://user/${u['qchatId']}',
                  size: 240,
                  backgroundColor: Colors.white,
                ),
                Text(u['qchatId']),
              ],
            ),
          );
        }
        return ListView(
          children: [
            MenuRow(
              'avatar',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QChatAvatar(u['nickname'], size: 34),
                  const SizedBox(width: 9),
                  const QChatIcon(
                    'chevron',
                    size: 18,
                    color: QChatColors.muted,
                  ),
                ],
              ),
            ),
            MenuRow(
              'name',
              value: u['nickname'],
              onTap: () => edit('nickname', 'name', u['nickname']),
            ),
            MenuRow('gender', value: tr(c, 'notSet')),
            const MenuRow('region'),
            MenuRow('phone', value: tr(c, 'notSet')),
            MenuRow('ID', value: u['qchatId'], onTap: () => c.push('/qr')),
            MenuRow(
              'qr',
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QChatIcon('qr', color: QChatColors.muted, size: 22),
                  SizedBox(width: 9),
                  QChatIcon('chevron', size: 18, color: QChatColors.muted),
                ],
              ),
              onTap: () => c.push('/qr'),
            ),
            const MenuRow('poke'),
            MenuRow(
              'status',
              value: (u['bio'] ?? '').toString().isEmpty
                  ? tr(c, 'notSet')
                  : u['bio'],
              onTap: () => edit('bio', 'status', u['bio'] ?? ''),
            ),
            sectionGap,
            const MenuRow('ringtone'),
            sectionGap,
            const MenuRow('addresses'),
            const MenuRow('invoice'),
            sectionGap,
            const MenuRow('beans'),
          ],
        );
      },
    ),
  );
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool scanned = false;
  @override
  Widget build(BuildContext c) => QChatPage(
    title: tr(c, 'scan'),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => c.pop(),
    ),
    child: MobileScanner(
      onDetect: (capture) {
        if (scanned) return;
        for (final barcode in capture.barcodes) {
          final uri = Uri.tryParse(barcode.rawValue ?? '');
          if (uri?.scheme == 'qchat' &&
              uri?.host == 'user' &&
              uri!.pathSegments.length == 1) {
            scanned = true;
            context.pushReplacement(
              '/friends?q=${Uri.encodeComponent(uri.pathSegments.first)}',
            );
            break;
          }
        }
      },
    ),
  );
}
