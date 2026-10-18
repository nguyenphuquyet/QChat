import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system/components.dart';
import '../../core/localization/strings.dart';

class MediaScreen extends ConsumerStatefulWidget {
  const MediaScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends ConsumerState<MediaScreen> {
  late Future<dynamic> data;
  @override
  void initState() {
    super.initState();
    data = ref
        .read(clientProvider)
        .get('/media/${widget.id}/access', cached: false);
  }

  @override
  Widget build(BuildContext c) => QChatPage(
    title: tr(c, 'image'),
    leading: QChatIconButton(
      'back',
      label: tr(c, 'back'),
      onTap: () => context.pop(),
    ),
    child: FutureBuilder<dynamic>(
      future: data,
      builder: (c, s) => s.hasError
          ? QChatError(
              error: s.error!,
              retry: () => setState(
                () => data = ref
                    .read(clientProvider)
                    .get('/media/${widget.id}/access', cached: false),
              ),
            )
          : !s.hasData
          ? const QChatLoading()
          : InteractiveViewer(
              minScale: .5,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  s.data['url'],
                  errorBuilder: (_, e, st) => QChatEmptyState(tr(c, 'file')),
                ),
              ),
            ),
    ),
  );
}
