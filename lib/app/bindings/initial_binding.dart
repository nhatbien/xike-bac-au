import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/breathing_settings.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/logging_service.dart';
import '../../core/services/audio_manifest.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/duration_calculator.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../features/breathing/breathing_controller.dart';

Future<void> initializeDependencies() async {
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  final storage = Get.put(StorageService(preferences), permanent: true);
  final logs = Get.put(LoggingService(storage), permanent: true);
  if (storage.read<Map>('activeSession') != null) {
    logs.log(
      'Buổi trước bị gián đoạn do tiến trình kết thúc; không ghi hoàn thành.',
    );
    await storage.remove('activeSession');
  }
  final settings = Get.put(SettingsRepository(storage, logs), permanent: true);
  final sessions = Get.put(SessionRepository(storage, logs), permanent: true);
  Get.put(BackupService(storage, settings, sessions), permanent: true);
  final text = await rootBundle.loadString('assets/am-thanh/lich.txt');
  final manifest = Get.put(AudioManifest.parse(text), permanent: true);
  final voiceManifests = <GuidanceVoice, AudioManifest>{};
  for (final voice in GuidanceVoice.values) {
    voiceManifests[voice] = voice == GuidanceVoice.original
        ? manifest
        : AudioManifest.parse(await rootBundle.loadString(voice.manifestAsset));
  }
  Get.put(
    DurationCalculator(manifest, voiceManifests: voiceManifests),
    permanent: true,
  );
  final handler = await AudioService.init(
    builder: () => TrainingAudioHandler(logs),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'vn.xike.breathing',
      androidNotificationChannelName: 'Buổi thở',
      androidNotificationIcon: 'drawable/ic_stat_tho',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );
  await handler.initialize();
  Get.put(handler, permanent: true);
  Get.put(
    BreathingController(
      handler,
      storage,
      logs,
      settings,
      sessions,
      manifest,
      text,
    ),
    permanent: true,
  );
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    previousErrorHandler?.call(details);
    logs.log('Flutter: ${details.exceptionAsString()}');
  };
  logs.log('Mở app Ìe Bắc Âu 1.0.0');
}
