import 'package:flutter/material.dart';

import '../../data/models/breathing_session.dart';
import '../../core/utils/time_formatter.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class TrainingCalendar extends StatefulWidget {
  final DateTime month;
  final List<BreathingSession> sessions;
  const TrainingCalendar({
    super.key,
    required this.month,
    required this.sessions,
  });
  @override
  State<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendar> {
  static const _initialPage = 12000;
  late final PageController _pages;
  int _page = _initialPage;

  DateTime _monthAt(int page) =>
      DateTime(widget.month.year, widget.month.month + page - _initialPage);

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant TrainingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year != widget.month.year ||
        oldWidget.month.month != widget.month.month) {
      _page = _initialPage;
      _pages.jumpToPage(_initialPage);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _move(int delta) => _pages.animateToPage(
    _page + delta,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) {
    final month = _monthAt(_page);
    return DashedBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSectionTitle(
                  'Lịch tập tháng ${month.month}/${month.year}',
                ),
              ),
              IconButton(
                tooltip: 'Tháng trước',
                onPressed: _page > 0 ? () => _move(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Tháng sau',
                onPressed: () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Reserve six weeks so every month fits without moving the page.
              final cellWidth = (constraints.maxWidth - 6 * 5) / 7;
              final cellHeight = (cellWidth * 1.08).clamp(
                48.0,
                double.infinity,
              );
              return SizedBox(
                height: cellHeight * 6 + 5 * 5,
                child: PageView.builder(
                  controller: _pages,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, page) =>
                      _buildMonth(_monthAt(page), cellHeight),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _dayColor(int seconds) {
    if (seconds <= 0) return const Color(0xFFF4EAD6);
    if (seconds < 15 * 60) return const Color(0xFFF0C397);
    if (seconds < 30 * 60) return const Color(0xFFEBA880);
    if (seconds < 60 * 60) return const Color(0xFFE68F73);
    return const Color(0xFFDF7B65);
  }

  Widget _buildMonth(DateTime month, double cellHeight) {
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final today = dayOf(DateTime.now());
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      mainAxisExtent: cellHeight,
      padding: EdgeInsets.zero,
      children: [
        ...List.generate(offset, (_) => const SizedBox()),
        ...List.generate(count, (i) {
          final date = DateTime(month.year, month.month, i + 1);
          final seconds = widget.sessions
              .where((s) => s.isCompleted && dayOf(s.startedAt) == date)
              .fold(0, (n, s) => n + s.totalDurationSeconds);
          final textColor = seconds >= 30 * 60
              ? AppColors.paper
              : seconds > 0
              ? AppColors.ink
              : AppColors.muted;
          return Container(
            decoration: BoxDecoration(
              color: _dayColor(seconds),
              borderRadius: BorderRadius.circular(10),
              border: date == today
                  ? Border.all(color: AppColors.teal, width: 2.5)
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${i + 1}',
                      style: body(
                        14,
                        color: textColor,
                        weight: seconds > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (seconds > 0)
                      Text(
                        '${(seconds / 60).round()}′',
                        style: body(10.5, color: textColor),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
