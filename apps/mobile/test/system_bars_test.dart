import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qchat/core/design_system/components.dart';

void main() {
  testWidgets('system insets follow screen surfaces without covering controls', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final color in [Colors.white, Colors.black]) {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(top: 44, bottom: 34)),
          child: QChatPage(
            statusBackground: color,
            navigationBackground: color,
            bottom: const SizedBox(key: Key('bottom-controls'), height: 50),
            child: const SizedBox.expand(key: Key('body')),
          ),
        ),
      ));
      expect(tester.getTopLeft(find.byKey(const Key('body'))).dy, 44);
      expect(tester.getBottomLeft(find.byKey(const Key('bottom-controls'))).dy, 810);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
      );
      expect(region.value.statusBarColor, Colors.transparent);
      expect(region.value.systemNavigationBarColor, Colors.transparent);
      expect(region.value.systemNavigationBarContrastEnforced, false);
      expect(region.value.statusBarIconBrightness, color == Colors.white ? Brightness.dark : Brightness.light);
      expect(region.value.statusBarBrightness, color == Colors.white ? Brightness.light : Brightness.dark);
      final insetColors = tester.widgetList<Positioned>(find.byType(Positioned))
          .where((position) => position.height == 44 || position.height == 34)
          .map((position) => (position.child as ColoredBox).color);
      expect(insetColors, [color, color]);
      expect(tester.takeException(), isNull);
    }
  });
}
