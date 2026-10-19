import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import '../localization/strings.dart';
import 'client.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.client,
    required this.child,
  });
  final QChatClient client;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: client.offline,
    builder: (context, offline, _) => Column(
      children: [
        if (offline)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.wifi_slash, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tr(context, 'offlineCache'))),
                    TextButton(
                      onPressed: client.reconnect,
                      child: Text(tr(context, 'retry')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    ),
  );
}
