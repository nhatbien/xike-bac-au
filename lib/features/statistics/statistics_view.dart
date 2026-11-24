import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/training_calendar.dart';
import '../../app/widgets/achievement_badge.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/repositories/statistics_repository.dart';
import '../sessions/session_detail_view.dart';
import 'statistics_controller.dart';
import 'add_badge_dialog.dart';

class StatisticsView extends GetView<StatisticsController> {
  const StatisticsView({super.key});
  @override
  Widget build(BuildContext context) => Obx(() {
    final stats = controller.stats;
    final range = controller.range;
    final selected = stats.within(range);
    final period = controller.period.value;
    final last = range.end.subtract(const Duration(days: 1));
    final title = switch (period) {
      Period.day =>
        'Ngày ${range.start.day}/${range.start.month}/${range.start.year}',
      Period.week =>
        'Tuần này: ${range.start.day}/${range.start.month} – ${last.day}/${last.month}/${last.year}',
      Period.month => 'Tháng ${range.start.month}/${range.start.year}',
      Period.year => 'Năm ${range.start.year}',
      Period.all => 'Tất cả buổi tập',
    };
    final achievements = stats.achievements;
    final customAchievements = controller.repository.customBadges
        .map(
          (badge) =>
              stats.achievementFor(badge.metric.key, badge.name, badge.target),
        )
        .toList();
    return AppPage(
      title: 'Thống kê',
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 8, top: 4),
                child: OutlinedButton(
                  onPressed: () => controller.select(Period.values[i]),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    backgroundColor: period.index == i
                        ? AppColors.ink
                        : const Color(0xFFFFFDF7),
                    foregroundColor: period.index == i
                        ? AppColors.background
                        : AppColors.ink,
                    side: const BorderSide(color: AppColors.border, width: 2),
                    textStyle: body(14.5, weight: FontWeight.w600),
                  ),
                  child: Text(
                    [
                      'Hôm nay',
                      'Tuần này',
                      'Tháng này',
                      'Năm nay',
                      'Tất cả',
                    ][i],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (period != Period.all)
          Row(
            children: [
              Expanded(
                child: RoundedOutlineButton(
                  '‹ Trước',
                  compact: true,
                  onPressed: controller.previous,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RoundedOutlineButton(
                  'Nay',
                  compact: true,
                  onPressed: controller.offset.value == 0
                      ? null
                      : () => controller.offset.value = 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RoundedOutlineButton(
                  'Sau ›',
                  compact: true,
                  onPressed: controller.offset.value == 0
                      ? null
                      : controller.next,
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
          child: Text(title, style: serif(21).copyWith(height: 1.5)),
        ),
        if (selected.isEmpty)
          EmptyStateCard(
            period == Period.week
                ? 'Không có buổi nào trong khoảng này.'
                : 'Không có buổi nào trong khoảng này.',
          )
        else ...[
          Row(
            children: [
              _metric('${selected.length}', 'buổi', AppColors.pink),
              const SizedBox(width: 8),
              _metric(
                '${selected.fold(0, (n, s) => n + s.totalDurationSeconds) ~/ 60}',
                'phút tập',
                AppColors.green,
              ),
              const SizedBox(width: 8),
              _metric(
                '${selected.fold(0, (n, s) => n + s.completedRounds)}',
                'hiệp',
                AppColors.yellow,
              ),
            ],
          ),
          ...selected.map(
            (s) => DashedBorderCard(
              onTap: () => Get.to(() => SessionDetailView(session: s)),
              child: Text(
                '${dateLabel(s.startedAt)} · ${s.completedRounds} hiệp · ${durationLabel(s.totalDurationSeconds)}',
                style: body(15),
              ),
            ),
          ),
          _TrainingChart(sessions: stats, range: range, period: period),
        ],
        DashedBorderCard(
          color: AppColors.yellow,
          borderColor: AppColors.mustard,
          child: Text(
            'Kỷ lục mọi thời: nín ${clock(stats.record)} · chuỗi hiện tại ${stats.currentStreak(DateTime.now())} ngày · chuỗi dài nhất ${stats.longestStreak} ngày',
            style: body(
              16,
              color: const Color(0xFF7A4F0A),
              weight: FontWeight.w600,
            ),
          ),
        ),
        TrainingCalendar(
          month: controller.offset.value == 0 ? DateTime.now() : range.start,
          sessions: controller.repository.sessions.toList(),
        ),
        DashedBorderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionTitle(
                'Huy hiệu (${achievements.where((a) => a.unlocked).length + customAchievements.where((a) => a.unlocked).length} đã đạt)',
              ),
              Text(
                'sticker màu là đã có, viền chấm là sắp tới',
                style: body(13.5, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...achievements.map((a) => AchievementBadge(a)),
                  ...controller.repository.customBadges.map(
                    (badge) => AchievementBadge(
                      stats.achievementFor(
                        badge.metric.key,
                        badge.name,
                        badge.target,
                      ),
                      onLongPress: () async {
                        final remove = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Xóa huy hiệu?'),
                            content: Text('Xóa huy hiệu “${badge.name}”?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (remove != true) return;
                        try {
                          await controller.repository.deleteBadge(badge.id);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chưa xóa được huy hiệu. Bạn thử lại nhé.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DashedBorderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nín thở vui: ${controller.repository.attempts.isEmpty ? 'chưa có lần thử' : 'kỷ lục ${stopwatchText(controller.repository.attempts.fold(0, (m, a) => m > a.durationMilliseconds ? m : a.durationMilliseconds))} · ${controller.repository.attempts.length} lần thử'}',
                style: body(15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                stats.sessions.isEmpty
                    ? 'Chưa có buổi nào. Buổi đầu tiên chỉ mất chừng mười lăm phút.'
                    : 'Đều đặn từng ngày, thêm một nhịp thở.',
                style: body(15),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Tập vừa sức, dừng khi cần. Thời gian ghi nhận không phải mục tiêu bắt buộc.',
            style: serif(16.5, color: AppColors.muted, italic: true),
            textAlign: TextAlign.center,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Semantics(
            button: true,
            child: DashedBorderCard(
              radius: 12,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    AddBadgeDialog(repository: controller.repository),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'Thêm huy hiệu',
                    style: body(13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  });
  Widget _metric(String value, String label, Color color) => Expanded(
    child: DashedBorderCard(
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        children: [
          Text(value, style: serif(28)),
          Text(label, style: body(13, color: AppColors.muted)),
        ],
      ),
    ),
  );
}

class _TrainingChart extends StatelessWidget {
  final StatisticsRepository sessions;
  final DateRange range;
  final Period period;
  const _TrainingChart({
    required this.sessions,
    required this.range,
    required this.period,
  });
  @override
  Widget build(BuildContext context) {
    final buckets = period == Period.year || period == Period.all
        ? 12
        : period == Period.month
        ? DateTime(range.start.year, range.start.month + 1, 0).day
        : period == Period.week
        ? 7
        : 1;
    final values = List<int>.filled(buckets, 0);
    for (final s in sessions.within(range)) {
      final index = period == Period.year || period == Period.all
          ? s.startedAt.month - 1
          : period == Period.day
          ? 0
          : dayOf(s.startedAt).difference(dayOf(range.start)).inDays;
      if (index >= 0 && index < buckets) {
        values[index] += s.totalDurationSeconds;
      }
    }
    final max = values.fold(1, (m, v) => m > v ? m : v);
    return DashedBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle('Phút tập'),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                buckets,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      height: (values[i] / max * 120).clamp(3, 120),
                      decoration: BoxDecoration(
                        color: values[i] > 0
                            ? AppColors.mustard
                            : AppColors.paperDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng ${values.fold(0, (a, b) => a + b) ~/ 60} phút trong khoảng này',
            style: body(13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
