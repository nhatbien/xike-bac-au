import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xike_bac_au/app/theme/app_theme.dart';
import 'package:xike_bac_au/features/statistics/statistics_view.dart';
import 'package:xike_bac_au/core/services/backup_service.dart';
import 'package:xike_bac_au/core/services/logging_service.dart';
import 'package:xike_bac_au/core/services/storage_service.dart';
import 'package:xike_bac_au/data/models/training_backup.dart';
import 'package:xike_bac_au/data/repositories/session_repository.dart';
import 'package:xike_bac_au/data/repositories/settings_repository.dart';
import 'package:xike_bac_au/features/statistics/add_badge_dialog.dart';
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

  test('Custom badge points persist and are removed on deletion', () async {
    final controller = StatisticsController(history);
    await history.addBadge('  Đều đặn  ', 25);
    expect(controller.badgePoints, 25);
    final restored = SessionRepository(storage, LoggingService(storage));
    expect(restored.customBadges.single.name, 'Đều đặn');
    expect(restored.customBadges.single.points, 25);
    await expectLater(history.addBadge('đều đặn', 10), throwsFormatException);
    await expectLater(history.addBadge('Sai', 0), throwsFormatException);
    await expectLater(history.addBadge(' ', 10), throwsFormatException);
    await history.deleteBadge(history.customBadges.single.id);
    expect(controller.badgePoints, 0);
    expect(
      SessionRepository(storage, LoggingService(storage)).customBadges,
      isEmpty,
    );
  });

  test('Failed writes do not award or remove points', () async {
    await history.addBadge('Có sẵn', 10);
    preferences.control.failure = StateError('write failed');
    await expectLater(history.addBadge('Mới', 20), throwsStateError);
    await expectLater(
      history.deleteBadge(history.customBadges.single.id),
      throwsStateError,
    );
    expect(StatisticsController(history).badgePoints, 10);
  });

  test(
    'Backup restores badges, supports old files and validates duplicates',
    () async {
      await history.addBadge('Kiên trì', 30);
      final snapshot = TrainingBackup.decode(backup.snapshot().encode());
      await history.deleteBadge(history.customBadges.single.id);
      await backup.restore(snapshot);
      expect(StatisticsController(history).badgePoints, 30);
      await history.addBadge('Thư giãn', 5);
      expect(
        SessionRepository(storage, LoggingService(storage)).customBadges,
        hasLength(2),
      );
      final json = jsonDecode(snapshot.encode()) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      (data['customBadges'] as List).add((data['customBadges'] as List).first);
      expect(
        () => TrainingBackup.decode(jsonEncode(json)),
        throwsFormatException,
      );
      data.remove('customBadges');
      await backup.restore(TrainingBackup.decode(jsonEncode(json)));
      expect(history.customBadges, isEmpty);
      expect(StatisticsController(history).badgePoints, 0);
    },
  );

  testWidgets('Add badge form validates and saves user supplied points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AddBadgeDialog(repository: history),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên huy hiệu.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Tập buổi sáng');
    await tester.enterText(find.byType(TextFormField).last, '45');
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    expect(find.byType(AddBadgeDialog), findsNothing);
    expect(history.customBadges.single.name, 'Tập buổi sáng');
    expect(StatisticsController(history).badgePoints, 45);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Statistics updates badge count and points after adding and deleting',
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
      await tester.enterText(find.byType(TextFormField).first, 'Buổi sáng');
      await tester.enterText(find.byType(TextFormField).last, '20');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Huy hiệu (1 đã đạt)'), findsOneWidget);
      expect(find.textContaining('20 điểm huy hiệu'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Xóa huy hiệu Buổi sáng'));
      await tester.tap(find.byTooltip('Xóa huy hiệu Buổi sáng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('Huy hiệu (0 đã đạt)'), findsOneWidget);
      expect(find.textContaining('0 điểm huy hiệu'), findsOneWidget);
      expect(history.customBadges, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
