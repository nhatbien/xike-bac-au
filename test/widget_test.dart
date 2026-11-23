import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xike_bac_au/core/services/audio_manifest.dart';
import 'package:xike_bac_au/core/utils/duration_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xike_bac_au/app/theme/app_theme.dart';
import 'package:xike_bac_au/app/widgets/app_widgets.dart';
import 'package:xike_bac_au/app/widgets/training_calendar.dart';
import 'package:xike_bac_au/data/models/breathing_session.dart';
import 'package:xike_bac_au/data/models/breathing_settings.dart';
import 'package:xike_bac_au/core/services/storage_service.dart';
import 'package:xike_bac_au/core/services/logging_service.dart';
import 'package:xike_bac_au/data/repositories/settings_repository.dart';
import 'package:xike_bac_au/data/repositories/session_repository.dart';
import 'package:xike_bac_au/features/settings/settings_controller.dart';
import 'package:xike_bac_au/features/settings/settings_view.dart';
import 'package:xike_bac_au/features/breath_hold/breath_hold_controller.dart';
import 'package:xike_bac_au/features/breath_hold/breath_hold_view.dart';
import 'package:xike_bac_au/features/sessions/sessions_controller.dart';
import 'package:xike_bac_au/features/sessions/sessions_view.dart';

class MemoryStorage extends GetxService implements StorageService {
  final values = <String, dynamic>{};
  @override
  T? read<T>(String key) => values[key] as T?;
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MemoryStorage storage;
  late LoggingService logs;
  late SettingsRepository settings;
  late SessionRepository sessions;
  setUp(() {
    Get.testMode = true;
    Get.put(
      DurationCalculator(
        AudioManifest.parse(
          File('assets/am-thanh/lich.txt').readAsStringSync(),
        ),
      ),
    );
    storage = MemoryStorage();
    logs = LoggingService(storage);
    settings = SettingsRepository(storage, logs);
    sessions = SessionRepository(storage, logs);
  });
  tearDown(() async {
    Get.reset();
  });
  Future<void> mount(WidgetTester t, Widget child) async {
    await t.pumpWidget(GetMaterialApp(theme: appTheme(), home: child));
    await t.pumpAndSettle();
  }

  testWidgets('Round grid and both sliders save settings immediately', (
    t,
  ) async {
    Get.put(SettingsController(settings));
    await mount(t, const SettingsView());
    await t.tap(find.byKey(const ValueKey('round-8')));
    await t.pumpAndSettle();
    expect(settings.settings.value.rounds, 8);
    expect(storage.read<Map>('settings')!['rounds'], 8);
    await t.drag(
      find.byKey(const ValueKey('hold-slider')),
      const Offset(120, 0),
    );
    await t.pumpAndSettle();
    expect(settings.settings.value.holdSeconds, greaterThan(90));
    await t.ensureVisible(find.byKey(const ValueKey('recovery-slider')));
    await t.drag(
      find.byKey(const ValueKey('recovery-slider')),
      const Offset(-100, 0),
    );
    await t.pumpAndSettle();
    expect(settings.settings.value.recoverySeconds, lessThan(40));
    expect(t.takeException(), isNull);
    final restored = SettingsRepository(storage, logs);
    expect(restored.settings.value.toJson(), settings.settings.value.toJson());
  });
  testWidgets(
    'Stopwatch starts, saves actual elapsed attempt and supports new attempt',
    (t) async {
      final c = Get.put(BreathHoldController(sessions, logs));
      await mount(t, const BreathHoldView());
      expect(find.text('0:00,0'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('stopwatch')));
      await t.pump(const Duration(milliseconds: 200));
      expect(c.running.value, true);
      // Stopwatch is monotonic, independently of fake widget-test timer time.
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)),
      );
      await t.tap(find.byKey(const ValueKey('stopwatch')));
      await t.pumpAndSettle();
      expect(sessions.attempts.length, 1);
      expect(c.elapsed.value, greaterThanOrEqualTo(1000));
      expect(c.finished.value, true);
      expect(c.record, sessions.attempts.first.durationMilliseconds);
      await c.deleteLast();
      await t.pumpAndSettle();
      expect(sessions.attempts, isEmpty);
      expect(c.elapsed.value, 0);
    },
  );
  testWidgets(
    'Calendar Monday offset, leap February and empty sessions fit small viewport',
    (t) async {
      t.view.physicalSize = const Size(320, 740);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await mount(
        t,
        AppPage(
          children: [
            TrainingCalendar(month: DateTime(2024, 2), sessions: const []),
          ],
        ),
      );
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
      expect(t.takeException(), isNull);
      Get.put(SessionsController(sessions));
      await mount(t, const SessionsView());
      expect(find.textContaining('Chưa có buổi nào.'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Calendar swipes across years and keeps session data per month', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final history = [
      BreathingSession(
        id: 'january',
        startedAt: DateTime(2025, 1, 15),
        completedAt: DateTime(2025, 1, 15, 0, 10),
        settings: const BreathingSettings(),
        completedRounds: 3,
        totalDurationSeconds: 600,
        totalHoldSeconds: 270,
      ),
    ];
    Widget calendar(DateTime month) => AppPage(
      children: [TrainingCalendar(month: month, sessions: history)],
    );
    await mount(t, calendar(DateTime(2024, 12)));
    expect(find.text('Lịch tập tháng 12/2024'), findsOneWidget);
    expect(find.text('10′'), findsNothing);

    await t.drag(find.byType(PageView), const Offset(-250, 0));
    await t.pumpAndSettle();
    expect(find.text('Lịch tập tháng 1/2025'), findsOneWidget);
    expect(find.text('10′'), findsOneWidget);

    await t.drag(find.byType(PageView), const Offset(250, 0));
    await t.pumpAndSettle();
    expect(find.text('Lịch tập tháng 12/2024'), findsOneWidget);
    expect(find.text('10′'), findsNothing);

    await t.tap(find.byTooltip('Tháng trước'));
    await t.pumpAndSettle();
    expect(find.text('Lịch tập tháng 11/2024'), findsOneWidget);
    await t.tap(find.byTooltip('Tháng sau'));
    await t.pumpAndSettle();
    expect(find.text('Lịch tập tháng 12/2024'), findsOneWidget);

    await mount(t, calendar(DateTime(2024, 2)));
    expect(find.text('Lịch tập tháng 2/2024'), findsOneWidget);
    expect(find.text('29'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('Navigation pushes and header returns to previous screen', (
    t,
  ) async {
    Get.put(SettingsController(settings));
    await mount(
      t,
      AppPage(
        children: [
          RoundedOutlineButton(
            'Mở cài đặt',
            onPressed: () => Get.to(() => const SettingsView()),
          ),
        ],
      ),
    );
    await t.tap(find.text('Mở cài đặt'));
    await t.pumpAndSettle();
    expect(find.text('Cài đặt buổi thở'), findsOneWidget);
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(find.text('Mở cài đặt'), findsOneWidget);
  });
  test(
    'Logs bounded, persistence reload and delete attempt propagate',
    () async {
      for (var i = 0; i < 350; i++) {
        logs.log('Sự kiện $i');
      }
      expect(logs.entries.length, 300);
      expect(LoggingService(storage).entries.length, 300);
    },
  );
}
