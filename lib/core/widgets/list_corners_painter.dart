import 'package:flutter/material.dart';

/// Masks only the corners; never draws an outline or a horizontal frame.
class ListCornersPainter extends CustomPainter {
  ListCornersPainter(this.color, {this.bottom = false, this.scroll})
    : super(repaint: scroll);
  final Color color;
  final bool bottom;
  final ScrollController? scroll;

  @override
  void paint(Canvas canvas, Size size) {
    if (bottom &&
        (scroll?.hasClients != true || scroll!.position.extentAfter <= .5)) {
      return;
    }
    final path = Path();
    if (bottom) {
      path
        ..moveTo(0, size.height)
        ..lineTo(20, size.height)
        ..quadraticBezierTo(0, size.height, 0, size.height - 20)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(20, 0)
        ..quadraticBezierTo(0, 0, 0, 20)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ListCornersPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.bottom != bottom ||
      oldDelegate.scroll != scroll;
}
