import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/utils/time_formatter.dart';
import 'sessions_controller.dart';
import 'session_detail_view.dart';

class SessionsView extends GetView<SessionsController> {
  const SessionsView({super.key});
  @override
  Widget build(BuildContext context) => Obx(
    () => AppPage(
      title: 'Các buổi đã tập',
      children: controller.repository.sessions.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'Chưa có buổi nào.\nMàn chính → Bắt đầu thở',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ]
          : controller.repository.sessions
                .map(
                  (s) => DashedBorderCard(
                    onTap: () => Get.to(() => SessionDetailView(session: s)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel(s.startedAt),
                          style: body(16, weight: FontWeight.w600),
                        ),
                        Text(
                          '${s.completedRounds} hiệp · ${durationLabel(s.totalDurationSeconds)}\nNín ${clock(s.settings.holdSeconds)} · giữ ${s.recoverySeconds} giây · hoàn thành',
                          style: body(14, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
    ),
  );
}
