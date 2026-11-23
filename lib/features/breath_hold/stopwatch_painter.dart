import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class StopwatchPainter extends CustomPainter {
  final int milliseconds, record;
  const StopwatchPainter(this.milliseconds, this.record);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300);
    const center = Offset(150, 150);
    final p = Paint()..isAntiAlias = true;
    canvas.drawCircle(
      center,
      142,
      p
        ..color = AppColors.paper
        ..style = PaintingStyle.fill,
    );
    p
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (double a = 0; a < 2 * pi; a += 13 / 142) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 142),
        a,
        7 / 142,
        false,
        p,
      );
    }
    canvas.drawCircle(
      center,
      134,
      p
        ..color = AppColors.paperDark
        ..strokeWidth = 2,
    );
    if (record > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 138),
        -pi / 2,
        2 * pi * (milliseconds / record).clamp(0, 1),
        false,
        p
          ..color =
              (milliseconds > record ? AppColors.coral : AppColors.mustard)
                  .withValues(alpha: .75)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < 60; i++) {
      final a = i * pi / 30;
      final r = i % 5 == 0 ? 118.0 : 124.0;
      canvas.drawLine(
        center + Offset(sin(a) * r, -cos(a) * r),
        center + Offset(sin(a) * 131, -cos(a) * 131),
        p
          ..color = (i % 5 == 0 ? AppColors.muted : AppColors.border)
          ..strokeWidth = (i % 5 == 0 ? 3 : 1.6)
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: '${i * 15}',
          style: serif(17, weight: FontWeight.w400, color: AppColors.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        center +
            Offset(sin(a) * 100, -cos(a) * 100) -
            Offset(tp.width / 2, tp.height / 2),
      );
    }
    canvas.save();
    canvas.translate(150, 150);
    canvas.rotate(milliseconds / 60000 * 2 * pi);
    canvas.drawLine(
      const Offset(0, 18),
      const Offset(0, -116),
      p
        ..color = AppColors.coral
        ..strokeWidth = 4,
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      8,
      p
        ..color = AppColors.coral
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, 3, p..color = AppColors.paper);
    canvas.restore();
  }

  @override
  bool shouldRepaint(StopwatchPainter old) =>
      old.milliseconds != milliseconds || old.record != record;
}
