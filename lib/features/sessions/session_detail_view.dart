import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/models/breathing_session.dart';
import '../../data/repositories/session_repository.dart';

class SessionDetailView extends StatelessWidget {
  final BreathingSession session;
  final bool completed;
  const SessionDetailView({
    super.key,
    required this.session,
    this.completed = false,
  });
  @override
  Widget build(BuildContext context) => AppPage(
    title: completed ? 'Xong buổi thở' : 'Buổi thở',
    children: [
      if (completed) ...[
        Text(
          'Tuyệt vời!',
          style: serif(40, color: AppColors.coral),
          textAlign: TextAlign.center,
        ),
        Text(
          '${session.completedRounds} hiệp trọn vẹn',
          style: body(17),
          textAlign: TextAlign.center,
        ),
      ],
      DashedBorderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel(session.startedAt),
              style: body(16, weight: FontWeight.w600),
            ),
            Text(
              '${session.completedRounds} hiệp · ${durationLabel(session.totalDurationSeconds)}\nNín tổng ${durationLabel(session.totalHoldSeconds)}\nGiữ phục hồi ${session.recoverySeconds} giây mỗi hiệp',
              style: body(16),
            ),
            Text(
              'Đã hoàn thành · cài đặt nín ${clock(session.settings.holdSeconds)}',
              style: body(13.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
      DashedBorderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionTitle('Nín từng hiệp'),
            ...List.generate(
              session.completedRounds,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Hiệp ${i + 1}',
                        style: body(15, weight: FontWeight.w600),
                      ),
                    ),
                    const Expanded(
                      child: LinearProgressIndicator(
                        value: 1,
                        minHeight: 18,
                        color: AppColors.teal,
                        backgroundColor: AppColors.paperDark,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      clock(session.settings.holdSeconds),
                      style: body(15, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'thanh xanh ngọc = nín đủ mức đã đặt',
              style: body(13.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '“Lúc muốn bỏ cuộc, thở thêm một nhịp nữa rồi hẵng tính.”',
          style: serif(16.5, color: AppColors.muted, italic: true),
          textAlign: TextAlign.center,
        ),
      ),
      if (completed)
        RoundedOutlineButton(
          'Về màn chính',
          primary: true,
          onPressed: () => Get.offAllNamed('/'),
        )
      else
        RoundedOutlineButton(
          'Xoá buổi này…',
          danger: true,
          onPressed: () async {
            if (await confirmAction(
              'Xoá buổi này?',
              dateLabel(session.startedAt),
              action: 'Xoá',
            )) {
              await Get.find<SessionRepository>().deleteSession(session.id);
              Get.back();
            }
          },
        ),
    ],
  );
}
