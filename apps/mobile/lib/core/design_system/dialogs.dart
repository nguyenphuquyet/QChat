import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../localization/strings.dart';
import 'components.dart';

Future<String?> editText(
  BuildContext context,
  String title, {
  String initial = '',
  int maxLength = 300,
  bool secret = false,
  int lines = 1,
}) {
  final controller = TextEditingController(text: initial);
  return TDialog.show<String>(
    context,
    barrierDismissible: true,
    dialog: StatefulBuilder(
      builder: (c, _) => TDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TInput(
            controller: controller,
            hintText: title,
            obscureText: secret,
            maxLines: lines,
            minLines: lines == 1 ? null : 1,
            autofocus: true,
            cursorColor: QChatColors.green,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TDialogAction(
            child: Text(tr(c, 'cancel')),
            variant: TButtonVariant.text,
          ),
          TDialogAction(
            child: Text(tr(c, 'save')),
            variant: TButtonVariant.text,
            role: TDialogActionRole.primary,
            onPressed: () => Navigator.pop(c, controller.text.trim()),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await TDialog.show<bool>(
      context,
      barrierDismissible: true,
      dialog: TDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TDialogAction(
            child: Text(tr(context, 'cancel')),
            variant: TButtonVariant.text,
            result: false,
          ),
          TDialogAction(
            child: Text(tr(context, 'confirm')),
            variant: TButtonVariant.text,
            role: TDialogActionRole.primary,
            result: true,
          ),
        ],
      ),
    ) ??
    false;
