import 'package:flutter/widgets.dart';

/// Original line icons drawn locally, independent of Material and WeChat assets.
class QChatIcon extends StatelessWidget {
  const QChatIcon(
    this.name, {
    super.key,
    this.color = const Color(0xff191919),
    this.size = 24,
  });
  final String name;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _IconPainter(name, color)),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.name, this.color);
  final String name;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (name) {
      case 'chats':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 15),
            const Radius.circular(6),
          ),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(7, 18)
            ..lineTo(5, 22)
            ..lineTo(12, 18),
          p,
        );
        break;
      case 'contacts':
      case 'me':
        canvas.drawCircle(const Offset(12, 7), 4, p);
        canvas.drawPath(
          Path()
            ..moveTo(3, 22)
            ..cubicTo(3, 13, 21, 13, 21, 22)
            ..close(),
          p,
        );
        break;
      case 'discover':
        canvas.drawCircle(const Offset(12, 12), 10, p);
        canvas.drawPath(
          Path()
            ..moveTo(16, 7)
            ..lineTo(14, 14)
            ..lineTo(7, 17)
            ..lineTo(10, 10)
            ..close(),
          p,
        );
        break;
      case 'search':
        canvas.drawCircle(const Offset(10, 10), 6, p);
        canvas.drawLine(const Offset(15, 15), const Offset(21, 21), p);
        break;
      case 'back':
        canvas.drawPath(
          Path()
            ..moveTo(15, 4)
            ..lineTo(7, 12)
            ..lineTo(15, 20),
          p,
        );
        break;
      case 'more':
        for (final x in [4.0, 12.0, 20.0]) {
          canvas.drawCircle(Offset(x, 12), 1.4, p..style = PaintingStyle.fill);
        }
        break;
      case 'plus':
        canvas.drawCircle(const Offset(12, 12), 10, p);
        canvas.drawLine(const Offset(6, 12), const Offset(18, 12), p);
        canvas.drawLine(const Offset(12, 6), const Offset(12, 18), p);
        break;
      case 'emoji':
        canvas.drawCircle(const Offset(12, 12), 10, p);
        canvas.drawArc(const Rect.fromLTWH(6, 7, 12, 11), 0.2, 2.7, false, p);
        canvas.drawCircle(const Offset(8, 8), .6, p);
        canvas.drawCircle(const Offset(16, 8), .6, p);
        break;
      case 'scan':
        for (final r in [
          const Rect.fromLTWH(2, 2, 7, 7),
          const Rect.fromLTWH(15, 2, 7, 7),
          const Rect.fromLTWH(2, 15, 7, 7),
        ]) {
          canvas.drawRect(r, p);
        }
        canvas.drawRect(const Rect.fromLTWH(15, 15, 6, 6), p);
        break;
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 3, 16, 18),
            const Radius.circular(3),
          ),
          p,
        );
        canvas.drawLine(const Offset(8, 9), const Offset(16, 9), p);
        canvas.drawLine(const Offset(8, 15), const Offset(16, 15), p);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.name != name || old.color != color;
}
