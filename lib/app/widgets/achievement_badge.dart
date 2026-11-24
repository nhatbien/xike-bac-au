import 'package:flutter/material.dart';

import '../../data/models/achievement.dart';
import '../../core/utils/time_formatter.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onLongPress;
  const AchievementBadge(this.achievement, {super.key, this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final remaining = (a.target - a.progress).clamp(0, a.target);
    final progress = switch (a.id) {
      'first' => 'còn $remaining buổi nữa',
      'hold' => 'còn ${clock(remaining)} nữa',
      'streak' => 'còn $remaining ngày liền nữa',
      'hour' => 'còn ${(remaining / 3600).ceil()} giờ tập nữa',
      _ => 'còn $remaining hiệp nữa',
    };
    return BadgeSticker(
      onLongPress: onLongPress,
      name: a.name,
      subtitle: a.unlocked
          ? 'đạt ${a.progress.clamp(0, a.target)} / ${a.target}'
          : progress,
      unlocked: a.unlocked,
    );
  }
}

class BadgeSticker extends StatelessWidget {
  final String name, subtitle;
  final bool unlocked;
  final VoidCallback? onLongPress;

  const BadgeSticker({
    super.key,
    required this.name,
    required this.subtitle,
    required this.unlocked,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DashedBorderCard(
        onLongPress: onLongPress,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: unlocked ? AppColors.yellow : AppColors.paper,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              'star',
              size: 20,
              color: unlocked ? AppColors.mustard : AppColors.border,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: body(
                      14.5,
                      color: unlocked ? AppColors.ink : AppColors.muted,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(subtitle, style: body(12, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
