import 'package:get/get.dart';

import '../../data/repositories/session_repository.dart';
import '../../data/repositories/statistics_repository.dart';

class StatisticsController extends GetxController {
  final SessionRepository repository;
  StatisticsController(this.repository);
  final period = Period.week.obs, offset = 0.obs;
  StatisticsRepository get stats => StatisticsRepository(repository.sessions);
  int get badgePoints =>
      stats.achievements.where((a) => a.unlocked).length * 10 +
      repository.customBadges.fold(0, (total, badge) => total + badge.points);
  DateRange get range =>
      DateRange.forPeriod(period.value, offset.value, DateTime.now());
  void select(Period p) {
    period.value = p;
    offset.value = 0;
  }

  void previous() => offset.value++;
  void next() {
    if (offset.value > 0) offset.value--;
  }
}
