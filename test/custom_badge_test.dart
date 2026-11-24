import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xike_bac_au/app/theme/app_theme.dart';
import 'package:xike_bac_au/app/widgets/achievement_badge.dart';
import 'package:xike_bac_au/features/statistics/statistics_view.dart';
import 'package:xike_bac_au/core/services/backup_service.dart';
import 'package:xike_bac_au/core/services/logging_service.dart';
import 'package:xike_bac_au/core/services/storage_service.dart';
import 'package:xike_bac_au/data/models/custom_badge.dart';
import 'package:xike_bac_au/data/models/breathing_session.dart';
import 'package:xike_bac_au/data/models/breathing_settings.dart';
import 'package:xike_bac_au/data/models/training_backup.dart';
import 'package:xike_bac_au/data/repositories/session_repository.dart';
import 'package:xike_bac_au/data/repositories/settings_repository.dart';
import 'package:xike_bac_au/data/repositories/statistics_repository.dart';
import 'package:xike_bac_au/features/statistics/statistics_controller.dart';

import 'storage_test.dart' show TestPreferences;

void main() {
  late TestPreferences preferences;
  late StorageService storage;
  late SessionRepository history;
  late BackupService backup;

  setUp(() {
    preferences = TestPreferences();
    storage = StorageService(preferences);
    final logs = LoggingService(storage);
    history = SessionRepository(storage, logs);
    backup = BackupService(storage, SettingsRepository(storage, logs), history);
  });

  BreathingSession session(int day, {bool completed = true}) =>
      BreathingSession(
        id: 'session-$day-$completed',
        startedAt: DateTime(2026, 11, day, 10),
        completedAt: DateTime(2026, 11, day, 10, 5),
        settings: const BreathingSettings(holdSeconds: 90),
        completedRounds: 1,
        totalDurationSeconds: 300,
        totalHoldSeconds: 90,
        isCompleted: completed,
      );

  test('Goals persist, reject duplicates and delete', () async {
    await history.addBadge(BadgeMetric.streak, 7);
    final restored = SessionRepository(storage, LoggingService(storage));
    expect(restored.customBadges.single.name, 'Chuỗi 7 ngày');
    expect(restored.customBadges.single.metric, BadgeMetric.streak);
    expect(restored.customBadges.single.target, 7);
    await expectLater(
      history.addBadge(BadgeMetric.streak, 7),
      throwsFormatException,
    );
    await expectLater(
      history.addBadge(BadgeMetric.hold, 0),
      throwsFormatException,
    );
    await history.deleteBadge(history.customBadges.single.id);
    expect(
      SessionRepository(storage, LoggingService(storage)).customBadges,
      isEmpty,
    );
  });

  test('Failed writes do not publish changes', () async {
    await history.addBadge(BadgeMetric.hold, 60);
    preferences.control.failure = StateError('write failed');
    await expectLater(
      history.addBadge(BadgeMetric.hold, 120),
      throwsStateError,
    );
    await expectLater(
      history.deleteBadge(history.customBadges.single.id),
      throwsStateError,
    );
    expect(history.customBadges.single.target, 60);
  });

  test('Backup round trips goals and accepts earlier formats', () async {
    await history.addBadge(BadgeMetric.trainingTime, 7200);
    final snapshot = TrainingBackup.decode(backup.snapshot().encode());
    await history.deleteBadge(history.customBadges.single.id);
    await backup.restore(snapshot);
    expect(history.customBadges.single.target, 7200);
    expect(history.customBadges.single.metric, BadgeMetric.trainingTime);
    final json = jsonDecode(snapshot.encode()) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    (data['customBadges'] as List).add((data['customBadges'] as List).first);
    expect(
      () => TrainingBackup.decode(jsonEncode(json)),
      throwsFormatException,
    );
    data['customBadges'] = [
      {
        'id': 'legacy',
        'name': 'Đều đặn',
        'points': 10,
        'createdAt': DateTime(2026, 11, 24).toIso8601String(),
      },
    ];
    final legacy = TrainingBackup.decode(jsonEncode(json));
    expect(legacy.customBadges.single.name, 'Đều đặn');
    expect(legacy.customBadges.single.target, 10);
    data.remove('customBadges');
    await backup.restore(TrainingBackup.decode(jsonEncode(json)));
    expect(history.customBadges, isEmpty);
  });

  test(
    'All goal types track completed history and recalculate after deletion',
    () async {
      await history.addSession(session(24));
      await history.addSession(session(25, completed: false));
      var stats = StatisticsRepository(history.sessions);
      expect(stats.achievementFor('hold', 'Nín thở 01:00', 60).progress, 90);
      expect(stats.achievementFor('streak', 'Chuỗi 3 ngày', 3).progress, 1);
      expect(stats.achievementFor('first', '2 buổi tập', 2).progress, 1);
      expect(stats.achievementFor('hour', '10 phút tập', 600).progress, 300);
      expect(stats.achievementFor('rounds', '2 hiệp', 2).progress, 1);
      await history.addSession(session(25));
      await history.addSession(session(26));
      stats = StatisticsRepository(history.sessions);
      final streak = stats.achievementFor('streak', 'Chuỗi 3 ngày', 3);
      expect(streak.unlocked, true);
      expect(streak.unlockedAt, session(26).completedAt);
      await history.deleteSession(session(25).id);
      expect(
        StatisticsRepository(history.sessions)
            .achievementFor('streak', 'Chuỗi 3 ngày', 3)
            .unlocked,
        false,
      );
    },
  );

  testWidgets(
    'Custom goals share earned and remaining subtitles with built-in badges',
    (tester) async {
      await history.addSession(session(24));
      await history.addBadge(BadgeMetric.hold, 60);
      await history.addBadge(BadgeMetric.streak, 3);
      final stats = StatisticsRepository(history.sessions);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: history.customBadges
                  .map(
                    (badge) => AchievementBadge(
                      stats.achievementFor(
                        badge.metric.key,
                        badge.name,
                        badge.target,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
      expect(find.text('Nín thở 01:00'), findsOneWidget);
      expect(find.text('đạt 60 / 60'), findsOneWidget);
      expect(find.text('Chuỗi 3 ngày'), findsOneWidget);
      expect(find.text('còn 2 ngày liền nữa'), findsOneWidget);
    },
  );

  testWidgets(
    'Add goal previews progress, counts earned only, and long press deletes',
    (tester) async {
      Get.testMode = true;
      Get.put(StatisticsController(history));
      addTearDown(() => Get.reset());
      await tester.pumpWidget(
        GetMaterialApp(theme: appTheme(), home: const StatisticsView()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm huy hiệu'));
      await tester.tap(find.text('Thêm huy hiệu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập mục tiêu từ 1 đến 9999.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '120');
      await tester.pumpAndSettle();
      expect(find.text('Nín thở 02:00'), findsOneWidget);
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(history.customBadges.single.target, 120);
      expect(find.text('Huy hiệu (0 đã đạt)'), findsOneWidget);
      expect(find.textContaining('điểm huy hiệu'), findsNothing);
      await tester.ensureVisible(find.text('Nín thở 02:00'));
      await tester.longPress(find.text('Nín thở 02:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(history.customBadges, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
