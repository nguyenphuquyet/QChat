import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.qr = false});
  final bool qr;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final name = TextEditingController(), bio = TextEditingController();
  late Future<dynamic> profile;
  bool initialized = false;
  String? error;
  @override
  void initState() {
    super.initState();
    profile = ref.read(clientProvider).get('/users/me');
  }

  @override
  void dispose() {
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
          padding: const EdgeInsets.all(20),
          children: [
            QChatTextInput(controller: name, hint: tr(c, 'nickname')),
            const SizedBox(height: 12),
            QChatTextInput(controller: bio, hint: tr(c, 'bio'), lines: 3),
            const SizedBox(height: 20),
            QChatButton(
              tr(c, 'save'),
              onTap: () async {
                try {
                  await ref
                      .read(clientProvider)
                      .dio
                      .patch(
                        '/users/me',
                        data: {'nickname': name.text, 'bio': bio.text},
                      );
                  if (c.mounted) c.pop();
                } catch (e) {
                  if (mounted) setState(() => error = tr(c, 'networkError'));
                }
              },
            ),
            if (error != null) Text(error!),
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

