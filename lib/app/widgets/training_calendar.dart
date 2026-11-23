import 'package:flutter/material.dart';

import '../../data/models/breathing_session.dart';
import '../../core/utils/time_formatter.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class TrainingCalendar extends StatelessWidget {
  final DateTime month;
  final List<BreathingSession> sessions;
  const TrainingCalendar({
    super.key,
    required this.month,
    required this.sessions,
  });
  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final today = dayOf(DateTime.now());
    return DashedBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionTitle('Lịch tập tháng ${month.month}/${month.year}'),
          Row(
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                .map(
                  (t) => Expanded(
                    child: Text(
                      t,
                      textAlign: TextAlign.center,
                      style: body(
                        12.5,
                        color: AppColors.muted,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1 / 1.08,
            children: [
              ...List.generate(offset, (_) => const SizedBox()),
              ...List.generate(count, (i) {
                final date = DateTime(month.year, month.month, i + 1);
                final seconds = sessions
                    .where((s) => dayOf(s.startedAt) == date)
                    .fold(0, (n, s) => n + s.totalDurationSeconds);
                return Container(
                  decoration: BoxDecoration(
                    color: seconds > 0
                        ? AppColors.yellow
                        : const Color(0xFFF4EAD6),
                    borderRadius: BorderRadius.circular(10),
                    border: date == today
                        ? Border.all(color: AppColors.teal, width: 2.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${i + 1}', style: body(14, color: AppColors.muted)),
                      if (seconds > 0)
                        Text('${(seconds / 60).round()}′', style: body(10.5)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
