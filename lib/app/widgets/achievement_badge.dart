import 'package:flutter/material.dart';

import '../../data/models/achievement.dart';
import '../../core/utils/time_formatter.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  const AchievementBadge(this.achievement, {super.key});
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DashedBorderCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: a.unlocked ? AppColors.yellow : AppColors.paper,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              'star',
              size: 20,
              color: a.unlocked ? AppColors.mustard : AppColors.border,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    style: body(
                      14.5,
                      color: a.unlocked ? AppColors.ink : AppColors.muted,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    a.unlocked ? 'đạt ${a.progress} / ${a.target}' : progress,
                    style: body(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
