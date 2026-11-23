import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart';
import 'package:xike_bac_au/main.dart' as app;
import 'package:xike_bac_au/core/services/logging_service.dart';
import 'package:xike_bac_au/data/models/breathing_settings.dart';
import 'package:xike_bac_au/core/services/storage_service.dart';
import 'package:xike_bac_au/data/repositories/settings_repository.dart';
import 'package:xike_bac_au/features/breathing/breathing_controller.dart';
import 'package:xike_bac_au/features/breath_hold/breath_hold_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Mobile navigation, persistence, stopwatch, audio lifecycle and screenshots',
    (tester) async {
      Future<void> capture(String name) async {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      final originalErrorHandler = FlutterError.onError;
      await app.main();
      FlutterError.onError = originalErrorHandler;
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      debugPrint("QA: converted surface");
      await capture('01-home');
      expect(find.text('Xì ke bắc âu'), findsOneWidget);
      Get.toNamed('/settings');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('round-5')));
      await tester.pumpAndSettle();
      expect(Get.find<SettingsRepository>().settings.value.rounds, 5);
      await tester.tap(find.byKey(const ValueKey('round-3')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('hold-slider')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
      expect(
        Get.find<SettingsRepository>().settings.value.holdSeconds,
        greaterThan(90),
      );
      await Get.find<SettingsRepository>().save(
        const BreathingSettings(holdSeconds: 240),
      );
      await tester.pumpAndSettle();
      await capture('05-settings');
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -380),
      );
      await tester.pumpAndSettle();
      await capture('05-settings-bottom');
      Get.back();
      await tester.pumpAndSettle();
      Get.toNamed('/hold');
      await tester.pumpAndSettle();
      await capture('04-stopwatch-empty');
      await tester.tap(find.byKey(const ValueKey('stopwatch')));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.tap(find.byKey(const ValueKey('stopwatch')));
      await tester.pumpAndSettle();
      expect(Get.find<BreathHoldController>().finished.value, true);
      expect(Get.find<BreathHoldController>().repository.attempts.length, 1);
      await capture('04-stopwatch-result');
      Get.back();
      await tester.pumpAndSettle();
      Get.toNamed('/statistics');
      await tester.pumpAndSettle();
      await capture('06-statistics');
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -540),
      );
      await tester.pumpAndSettle();
      await capture('06-statistics-bottom');
      Get.back();
      await tester.pumpAndSettle();
      Get.toNamed('/sessions');
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có buổi nào.'), findsOneWidget);
      await capture('08-sessions');
      Get.back();
      await tester.pumpAndSettle();
      await Get.find<SettingsRepository>().save(const BreathingSettings());
      Get.toNamed('/breathing');
      await tester.pump(const Duration(seconds: 1));
      final c = Get.find<BreathingController>();
      for (var i = 0; i < 60 && c.loading.value; i++) {
        await tester.pump(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(c.error.value, isEmpty);
      expect(c.active.value, true);
      await tester.pump(const Duration(seconds: 1));
      final beforeLock = c.audio.player.position.inMilliseconds;
      await capture('02-breathing');
      debugPrint(Platform.isAndroid ? 'QA_SCREEN_LOCK' : 'QA_IOS_BACKGROUND');
      if (Platform.isIOS) {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          39551,
        );
        socket.write('background');
        await socket.flush();
        final response = await socket.first.timeout(
          const Duration(seconds: 20),
        );
        expect(String.fromCharCodes(response), 'returned');
        await socket.close();
      } else {
        await Future<void>.delayed(const Duration(seconds: 8));
      }

      await tester.pump();
      expect(
        c.audio.player.position.inMilliseconds - beforeLock,
        greaterThan(4000),
      );
      await c.togglePause();
      final paused = c.audio.player.position.inMilliseconds;
      await tester.pump(const Duration(seconds: 2));
      expect(
        (c.audio.player.position.inMilliseconds - paused).abs(),
        lessThan(100),
      );
      await capture('03-breathing-paused');
      await c.togglePause();
      await tester.pump(const Duration(seconds: 1));
      expect(c.audio.player.playing, true);
      expect(c.audio.player.position.inMilliseconds, greaterThan(paused));
      await c.stop();
      Get.back();
      await tester.pumpAndSettle();
      expect(c.sessions.sessions, isEmpty);
      // Reach the real decoder's end without a 14-minute test wait.
      Get.toNamed('/breathing');
      await tester.pump(const Duration(seconds: 1));
      for (var i = 0; i < 30 && c.loading.value; i++) {
        await tester.pump(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await c.audio.player.seek(
        Duration(milliseconds: c.engine!.totalMs - 400),
      );
      await tester.pump(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(c.sessions.sessions.length, 1);
      expect(c.result.value?.isCompleted, true);
      expect(Get.find<StorageService>().read<Map>('activeSession'), isNull);
      await capture('09-completed');
      Get.offAllNamed('/');
      await tester.pumpAndSettle();
      Get.toNamed('/sessions');
      await tester.pumpAndSettle();
      await capture('08-sessions-populated');
      Get.back();
      await tester.pumpAndSettle();
      Get.toNamed('/logs');
      await tester.pumpAndSettle();
      await capture('07-logs');
      expect(
        Get.find<LoggingService>().entries.any(
          (l) => l.contains('Nạp âm thanh thành công'),
        ),
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
