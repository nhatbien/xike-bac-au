import 'dart:math';

import '../models/breathing_session.dart';
import '../models/achievement.dart';
import '../../core/utils/time_formatter.dart';

enum Period { day, week, month, year, all }

class DateRange {
  final DateTime start, end;
  const DateRange(this.start, this.end);
  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  static DateRange forPeriod(Period p, int offset, DateTime now) {
    final d = dayOf(now);
    switch (p) {
      case Period.day:
        final s = DateTime(d.year, d.month, d.day - offset);
        return DateRange(s, DateTime(s.year, s.month, s.day + 1));
      case Period.week:
        final s = DateTime(d.year, d.month, d.day - d.weekday + 1 - offset * 7);
        return DateRange(s, DateTime(s.year, s.month, s.day + 7));
      case Period.month:
        final s = DateTime(d.year, d.month - offset);
        return DateRange(s, DateTime(s.year, s.month + 1));
      case Period.year:
        return DateRange(
          DateTime(d.year - offset),
          DateTime(d.year - offset + 1),
        );
      case Period.all:
        return DateRange(DateTime(1970), DateTime(d.year + 1));
    }
  }
}

class StatisticsRepository {
  final List<BreathingSession> sessions;
  StatisticsRepository(Iterable<BreathingSession> values)
    : sessions = values.where((s) => s.isCompleted).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  int get totalSeconds =>
      sessions.fold(0, (s, x) => s + x.totalDurationSeconds);
  int get rounds => sessions.fold(0, (s, x) => s + x.completedRounds);
  int get record => sessions.fold(0, (s, x) => max(s, x.settings.holdSeconds));
  List<DateTime> get days =>
      sessions.map((s) => dayOf(s.startedAt)).toSet().toList()..sort();
  int get longestStreak {
    int best = 0, run = 0;
    DateTime? last;
    for (final d in days) {
      run = last != null && DateTime(last.year, last.month, last.day + 1) == d
          ? run + 1
          : 1;
      best = max(best, run);
      last = d;
    }
    return best;
  }

  int currentStreak(DateTime now) {
    final ds = days.toSet();
    var cursor = dayOf(now);
    if (!ds.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var n = 0;
    while (ds.contains(cursor)) {
      n++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return n;
  }

  List<BreathingSession> within(DateRange range) => sessions
      .where((s) => range.contains(s.startedAt))
      .toList()
      .reversed
      .toList();
  List<Achievement> get achievements {
    final specs = [
      ('first', 'Buổi đầu tiên', 1),
      ('hold', 'Nín 01:00', 60),
      ('streak', 'Chuỗi 3 ngày', 3),
      ('hour', '1 giờ tập', 3600),
      ('rounds', '50 hiệp', 50),
    ];
    final result = <Achievement>[];
    for (final spec in specs) {
      DateTime? reached;
      int progress = 0;
      final prefix = <BreathingSession>[];
      for (final s in sessions) {
        prefix.add(s);
        final r = StatisticsRepository(prefix);
        progress = switch (spec.$1) {
          'first' => prefix.length,
          'hold' => r.record,
          'streak' => r.longestStreak,
          'hour' => r.totalSeconds,
          _ => r.rounds,
        };
        if (progress >= spec.$3 && reached == null) reached = s.completedAt;
      }
      result.add(Achievement(spec.$1, spec.$2, progress, spec.$3, reached));
    }
    return result;
  }
}
