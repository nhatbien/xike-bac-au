import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.background,
      gradient: RadialGradient(
        center: Alignment(-.76, -1),
        radius: 1.4,
        colors: [Color(0xFFFFFDFA), AppColors.background],
      ),
    ),
    child: CustomPaint(painter: _PaperPainter(), child: child),
  );
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x04785A32)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) => false;
}

class AppPage extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final ScrollController? scrollController;
  const AppPage({
    super.key,
    this.title,
    required this.children,
    this.scrollController,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [if (title != null) AppHeader(title!), ...children],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppHeader extends StatelessWidget {
  final String title;
  const AppHeader(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          height: 42,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Get.back(),
            tooltip: 'Quay lại',
            icon: Text('‹', style: serif(30, weight: FontWeight.w400)),
          ),
        ),
        Expanded(child: Text(title, style: serif(24))),
      ],
    ),
  );
}

class DashedBorderCard extends StatelessWidget {
  final Widget child;
  final Color color, borderColor;
  final EdgeInsets padding, margin;
  final double radius;
  final VoidCallback? onTap;
  const DashedBorderCard({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.borderColor = AppColors.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.margin = const EdgeInsets.symmetric(vertical: 7),
    this.radius = 18,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: .25),
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0x0B785A32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: DashedPainter(borderColor, radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: padding + const EdgeInsets.all(2),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class DashedPainter extends CustomPainter {
  final Color color;
  final double radius;
  const DashedPainter(this.color, this.radius);
  @override
  void paint(Canvas c, Size s) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(1, 1) & Size(s.width - 2, s.height - 2),
          Radius.circular(radius - 1),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        c.drawPath(metric.extractPath(d, min(d + 6, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedPainter old) =>
      old.color != color || old.radius != radius;
}

class AppSectionTitle extends StatelessWidget {
  final String text;
  const AppSectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: serif(18).copyWith(height: 1.5)),
  );
}

class RoundedOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool primary, danger, compact;
  const RoundedOutlineButton(
    this.text, {
    super.key,
    this.onPressed,
    this.primary = false,
    this.danger = false,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? 0.4 : 1.0,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, compact ? 40 : 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 6 : 10,
        ),
        backgroundColor: primary
            ? AppColors.coral
            : danger
            ? const Color(0xFFFBE3DA)
            : AppColors.paperDark,
        foregroundColor: primary
            ? const Color(0xFFFFFDF7)
            : danger
            ? const Color(0xFF9E3E25)
            : AppColors.ink,
        side: BorderSide(
          color: primary
              ? const Color(0xFFC8634A)
              : danger
              ? const Color(0xFFE9A891)
              : AppColors.border,
          width: 2,
        ),
        textStyle: body(compact ? 15 : 16, weight: FontWeight.w600),
      ),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

class AppIcon extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const AppIcon(
    this.name, {
    super.key,
    this.color = AppColors.ink,
    this.size = 24,
  });
  @override
  Widget build(BuildContext context) {
    final shapes = <String, String>{
      'timer': '<circle cx="12" cy="13" r="8"/><path d="M12 13V9M9.5 2.5h5M12 2.5V5M18.5 6.5l1.5-1.5"/>',
      'settings': '<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2.2"/><circle cx="10" cy="17" r="2.2"/>',
      'stats': '<path d="M5 20V11M10 20V5M15 20v-7M20 20V8M3 20.5h18"/>',
      'sessions': '<rect x="4" y="3.5" width="16" height="17" rx="2.5"/><path d="M8 8h8M8 12h8M8 16h5"/>',
      'logs': '<path d="M4 20l1-4L16 5l3 3L8 19l-4 1zM14 7l3 3"/>',
      'wind': '<path d="M3 9h11a3 3 0 1 0-3-3M3 13h15a3 3 0 1 1-3 3M3 17h7"/>',
      'star': '<path fill="currentColor" stroke="none" d="M12 2.8l2.7 5.7 6.2.8-4.6 4.3 1.2 6.2L12 16.9 6.5 19.8l1.2-6.2L3.1 9.3l6.2-.8z"/>',
      'snow': [0, 60, 120, 180, 240, 300]
          .map(
            (r) =>
                '<g transform="rotate($r 12 12)"><path d="M12 12V2.6M12 5.2 9.8 3.4M12 5.2l2.2-1.8M12 8.4l-1.8-1.5M12 8.4l1.8-1.5"/></g>',
          )
          .join(),
    };
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${shapes[name] ?? shapes['snow']}</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class PrimaryActionCard extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onTap;
  const PrimaryActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 9, bottom: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8896F), AppColors.coral, Color(0xFFD86E52)],
      ),
      border: Border.all(color: const Color(0xFFC8634A), width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0xFFC25E46), offset: Offset(0, 3)),
        BoxShadow(
          color: Color(0x40E07A5F),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIcon('wind', color: Color(0xFFFFFDF7), size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      style: serif(
                        27,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFFFDF7),
                      ).copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 330
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          subtitle,
                          style: body(14.5, color: const Color(0xFFFFFDF7)),
                        ),
                      )
                    : Text(
                        subtitle,
                        style: body(14.5, color: const Color(0xFFFFFDF7)),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmptyStateCard extends StatelessWidget {
  final String text;
  const EmptyStateCard(this.text, {super.key});
  @override
  Widget build(BuildContext context) => DashedBorderCard(
    child: Text(text, style: body(16, color: AppColors.muted)),
  );
}

class BreathingProgressBar extends StatelessWidget {
  final double progress;
  final bool total;
  const BreathingProgressBar(this.progress, {super.key, this.total = false});
  @override
  Widget build(BuildContext context) => Container(
    height: total ? 6 : 10,
    margin: EdgeInsets.only(top: total ? 8 : 12),
    decoration: BoxDecoration(
      color: const Color(0xFFEFE3CC),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              colors: total
                  ? [AppColors.pink, AppColors.coral]
                  : [AppColors.green, AppColors.mint],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<bool> confirmAction(
  String title,
  String message, {
  String action = 'Dừng',
}) async =>
    await Get.dialog<bool>(
      AlertDialog(
        title: Text(title, style: serif(22)),
        content: Text(message, style: body(15)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
