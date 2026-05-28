import 'dart:math' as math;
import 'package:flutter/material.dart';

class CurvedTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle textStyle;
  final double startAngle;
  final bool reverse; // To draw on bottom arc correctly (right-side up)

  CurvedTextPainter({
    required this.text,
    required this.radius,
    required this.textStyle,
    this.startAngle = 0,
    this.reverse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    canvas.translate(centerX, centerY);
    canvas.rotate(startAngle);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    double totalArc = 0;
    final List<double> charWidths = [];

    for (int i = 0; i < text.length; i++) {
        textPainter.text = TextSpan(text: text[i], style: textStyle);
        textPainter.layout();
        final double width = textPainter.width;
        charWidths.add(width);
        totalArc += width / radius;
    }

    // Centering the text arc relative to the current rotation
    canvas.rotate(-totalArc / 2);

    for (int i = 0; i < text.length; i++) {
      final double charArc = charWidths[i] / radius;
      
      // Move to middle of character arc for rotation
      canvas.rotate(charArc / 2);
      
      textPainter.text = TextSpan(text: text[i], style: textStyle);
      textPainter.layout();

      final double x = -textPainter.width / 2;
      final double y = reverse ? radius : -radius - textPainter.height;

      if (reverse) {
        // For bottom arc, we need to flip the text so it's not upside down
        canvas.save();
        canvas.translate(0, radius);
        canvas.rotate(math.pi);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
        canvas.restore();
      } else {
        textPainter.paint(canvas, Offset(x, y));
      }

      canvas.rotate(charArc / 2);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
