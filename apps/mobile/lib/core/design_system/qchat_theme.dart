import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'qchat_colors.dart';

ThemeData qchatTheme(bool dark) => ThemeData(
  brightness: dark ? Brightness.dark : Brightness.light,
  scaffoldBackgroundColor: dark
      ? const Color(0xff111111)
      : QChatColors.background,
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  colorSchemeSeed: QChatColors.green,
  fontFamily: 'Arial',
  extensions: [
    TThemeData.defaultData(),
    TInputThemeData(
      backgroundColor: dark ? const Color(0xff222222) : Colors.white,
      borderColor: dark ? const Color(0xff333333) : QChatColors.line,
      borderRadius: 5,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  ],
);
