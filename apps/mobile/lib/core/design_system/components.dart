import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../localization/strings.dart';
import 'qchat_colors.dart';
import 'qchat_icons.dart';
import 'qchat_typography.dart';
export 'qchat_colors.dart';
export 'qchat_icons.dart';

Color surface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xff202020)
    : Colors.white;
Color ink(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xffeeeeee)
    : QChatColors.ink;

class QChatPage extends StatelessWidget {
  const QChatPage({
    super.key,
    required this.child,
    this.title,
    this.leading,
    this.trailing,
    this.bottom,
  });
  final Widget child;
  final String? title;
  final Widget? leading, trailing, bottom;
  @override
  Widget build(BuildContext c) => ColoredBox(
    color: Theme.of(c).scaffoldBackgroundColor,
    child: SafeArea(
      child: Column(
        children: [
          if (title != null)
            QChatAppBar(title: title!, leading: leading, trailing: trailing),
          Expanded(child: child),
          ?bottom,
        ],
      ),
    ),
  );
}

class QChatAppBar extends StatelessWidget {
  const QChatAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });
  final String title;
  final Widget? leading, trailing;
  @override
  Widget build(BuildContext c) => Container(
    height: 56,
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: ink(c).withValues(alpha: .07), width: .5),
      ),
    ),
    child: Row(
      children: [
        SizedBox(width: 64, child: leading),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: QChatTypography.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 64, child: trailing),
      ],
    ),
  );
}

class QChatIconButton extends StatelessWidget {
  const QChatIconButton(
    this.icon, {
    super.key,
    required this.label,
    required this.onTap,
    this.color,
  });
  final String icon, label;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext c) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(child: QChatIcon(icon, color: color ?? ink(c))),
      ),
    ),
  );
}

class QChatButton extends StatelessWidget {
  const QChatButton(this.text, {super.key, this.onTap, this.secondary = false});
  final String text;
  final VoidCallback? onTap;
  final bool secondary;
  @override
  Widget build(BuildContext c) => TButton(
    onPressed: onTap,
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        secondary ? surface(c) : QChatColors.green,
      ),
      foregroundColor: WidgetStatePropertyAll(
        secondary ? QChatColors.green : Colors.white,
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(90, 44)),
    ),
    child: Text(text),
  );
}

class QChatTextInput extends StatelessWidget {
  const QChatTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.secret = false,
    this.lines = 1,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final bool secret;
  final int lines;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext c) => TInput(
    controller: controller,
    hintText: hint,
    obscureText: secret,
    maxLines: lines,
    minLines: lines == 1 ? null : 1,
    onChanged: onChanged,
    cursorColor: QChatColors.green,
    style: TextStyle(color: ink(c), fontSize: 16),
  );
}

class QChatSearchBar extends StatelessWidget {
  const QChatSearchBar({super.key, required this.controller, this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: TInput(
      controller: controller,
      hintText: tr(c, 'search'),
      prefix: const QChatIcon('search', size: 18, color: QChatColors.muted),
      onChanged: onChanged,
      borderless: true,
    ),
  );
}

class QChatAvatar extends StatelessWidget {
  const QChatAvatar(this.name, {super.key, this.size = 48, this.url});
  final String name;
  final double size;
  final String? url;
  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: Container(
      width: size,
      height: size,
      color: const Color(0xffd7eade),
      alignment: Alignment.center,
      child: url != null
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => _letter(),
            )
          : _letter(),
    ),
  );
  Widget _letter() => Text(
    name.isEmpty ? 'Q' : name.characters.first.toUpperCase(),
    style: TextStyle(
      fontSize: size * .42,
      fontWeight: FontWeight.w500,
      color: const Color(0xff326b4c),
    ),
  );
}

class QChatUnreadBadge extends StatelessWidget {
  const QChatUnreadBadge(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext c) => count < 1
      ? const SizedBox.shrink()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: QChatColors.danger,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
}

class QChatListTile extends StatelessWidget {
  const QChatListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => Semantics(
    button: onTap != null,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: surface(c),
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 15, 16, 15),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: ink(c).withValues(alpha: .07),
                      width: .5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: QChatColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class QChatConversationTile extends StatelessWidget {
  const QChatConversationTile({
    super.key,
    required this.name,
    required this.preview,
    required this.onTap,
    this.unread = 0,
  });
  final String name, preview;
  final int unread;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => QChatListTile(
    title: name,
    subtitle: preview,
    leading: QChatAvatar(name),
    trailing: QChatUnreadBadge(unread),
    onTap: onTap,
  );
}

class QChatBottomNavigation extends StatelessWidget {
  const QChatBottomNavigation({
    super.key,
    required this.index,
    required this.onChanged,
  });
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext c) => Container(
    decoration: BoxDecoration(
      color: surface(c),
      border: Border(
        top: BorderSide(color: ink(c).withValues(alpha: .12), width: .5),
      ),
    ),
    child: Row(
      children: [
        for (int i = 0; i < 4; i++)
          Expanded(
            child: Semantics(
              selected: index == i,
              button: true,
              label: tr(c, ['chats', 'contacts', 'discover', 'me'][i]),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QChatIcon(
                        ['chats', 'contacts', 'discover', 'me'][i],
                        color: index == i ? QChatColors.green : ink(c),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(c, ['chats', 'contacts', 'discover', 'me'][i]),
                        style: TextStyle(
                          fontSize: 11,
                          color: index == i ? QChatColors.green : ink(c),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class QChatEmptyState extends StatelessWidget {
  const QChatEmptyState(this.text, {super.key, this.icon = 'chats'});
  final String text, icon;
  @override
  Widget build(BuildContext c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QChatIcon(icon, size: 48, color: QChatColors.muted),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: QChatColors.muted, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class QChatLoading extends StatelessWidget {
  const QChatLoading({super.key});
  @override
  Widget build(BuildContext c) => Center(
    child: Text(
      tr(c, 'loading'),
      style: const TextStyle(color: QChatColors.muted),
    ),
  );
}

class QChatChatBubble extends StatelessWidget {
  const QChatChatBubble({
    super.key,
    required this.mine,
    required this.name,
    required this.child,
    this.onLongPress,
  });
  final bool mine;
  final String name;
  final Widget child;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext c) {
    final avatar = QChatAvatar(name, size: 38);
    final bubble = Flexible(
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(c).width * .68,
          ),
          decoration: BoxDecoration(
            color: mine ? QChatColors.bubble : surface(c),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: mine ? QChatColors.ink : ink(c),
              fontSize: 16,
              height: 1.4,
            ),
            child: child,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: mine ? [bubble, avatar] : [avatar, bubble],
      ),
    );
  }
}

Future<void> qchatSheet(
  BuildContext context,
  List<(String, VoidCallback)> actions,
) => showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: tr(context, 'cancel'),
  barrierColor: const Color(0x66000000),
  transitionDuration: const Duration(milliseconds: 160),
  pageBuilder: (c, _, _) => Align(
    alignment: Alignment.bottomCenter,
    child: DefaultTextStyle(
      style: TextStyle(color: ink(c), fontSize: 16),
      child: Container(
        color: surface(c),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions)
              QChatListTile(
                title: action.$1,
                onTap: () {
                  Navigator.pop(c);
                  action.$2();
                },
              ),
            QChatListTile(
              title: tr(c, 'cancel'),
              onTap: () => Navigator.pop(c),
            ),
          ],
        ),
      ),
    ),
  ),
);

class QChatError extends StatelessWidget {
  const QChatError({super.key, required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext c) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tr(c, 'networkError')),
        const SizedBox(height: 16),
        QChatButton(tr(c, 'retry'), onTap: retry),
      ],
    ),
  );
}
