import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/utils/time_formatter.dart';
import 'breath_hold_controller.dart';
import 'stopwatch_painter.dart';

class BreathHoldView extends GetView<BreathHoldController> {
  const BreathHoldView({super.key});
  @override
  Widget build(BuildContext context) => Obx(() {
    final attempts = controller.repository.attempts;
    final now = DateTime.now();
    final today = attempts
        .where((a) => dayOf(a.createdAt) == dayOf(now))
        .length;
    final week = attempts
        .where(
          (a) =>
              !dayOf(a.createdAt)
                  .isBefore(DateTime(now.year, now.month, now.day - 6)),
        )
        .toList();
    final average = week.isEmpty
        ? 0
        : week.fold(0, (s, a) => s + a.durationMilliseconds) ~/ week.length;
    final ms = controller.elapsed.value;
    final isRunning = controller.running.value;
    return AppPage(
      title: 'Nín thở vui',
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final width = min(c.maxWidth * .9, 340.0);
            return Center(
              child: Semantics(
                button: true,
                label: isRunning ? 'Dừng nín thở' : 'Bắt đầu nín thở',
                child: GestureDetector(
                  key: const ValueKey('stopwatch'),
                  onTap: controller.tap,
                  child: SizedBox(
                    width: width,
                    height: width,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: StopwatchPainter(ms, controller.record),
                          ),
                        ),
                        Positioned(
                          top: width * .57,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paper.withValues(alpha: .85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  stopwatchText(ms),
                                  style: serif(40, weight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                ms >= 60000 ? 'vòng ${ms ~/ 60000 + 1}' : '',
                                style: body(14, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          isRunning
              ? 'Đang nín… bình tĩnh, thả lỏng vai'
              : controller.finished.value
              ? (controller.newRecord.value
                    ? 'KỶ LỤC MỚI: ${stopwatchText(ms)}!'
                    : ms < 1000
                    ? 'Bấm nhầm rồi, thử lại nhé'
                    : 'Lần này ${stopwatchText(ms)}')
              : 'Hít thở vài hơi, thở ra hết, rồi chạm để bắt đầu nín',
          style: controller.newRecord.value
              ? serif(24, color: AppColors.coral)
              : body(17, weight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          isRunning
              ? 'chạm để dừng khi cần thở'
              : controller.finished.value
              ? 'chạm đồng hồ để thử lần nữa'
              : 'chạm vào mặt đồng hồ',
          style: body(14.5, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        DashedBorderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionTitle(
                controller.record == 0
                    ? 'chưa có kỷ lục'
                    : 'Kỷ lục ${stopwatchText(controller.record)}',
              ),
              Text(
                'hôm nay $today lần · TB 7 ngày ${stopwatchText(average)}',
                style: body(15, color: AppColors.muted),
              ),
              ...attempts
                  .take(8)
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateLabel(a.createdAt),
                            style: body(14, color: AppColors.muted),
                          ),
                          Text(
                            stopwatchText(a.durationMilliseconds),
                            style: body(15, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (controller.lastId != null && controller.finished.value)
                RoundedOutlineButton(
                  'Xoá lần vừa rồi',
                  onPressed: () async {
                    if (await confirmAction(
                      'Xoá lần nín vừa rồi?',
                      'Xoá rồi không lấy lại được.',
                      action: 'Xoá',
                    )) {
                      controller.deleteLast();
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  });
}
