import 'dart:io';
import 'dart:async';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/audio_manifest.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/breathing_engine.dart';
import '../../core/services/logging_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/breathing_session.dart';
import '../../data/models/breathing_settings.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';

class BreathingController extends GetxController {
  final TrainingAudioHandler audio;
  final StorageService storage;
  final LoggingService logs;
  final SettingsRepository settings;
  final SessionRepository sessions;
  final AudioManifest manifest;
  final String manifestText;
  BreathingController(
    this.audio,
    this.storage,
    this.logs,
    this.settings,
    this.sessions,
    this.manifest,
    this.manifestText,
  );
  final loading = false.obs, active = false.obs, paused = false.obs;
  final error = ''.obs;
  final snapshot = Rxn<BreathingSnapshot>();
  final result = Rxn<BreathingSession>();
  BreathingEngine? engine;
  DateTime? startedAt;
  Timer? _ticker;
  bool _finishing = false;
  int _generation = 0;
  @override
  void onInit() {
    super.onInit();
    audio.onComplete = _complete;
    audio.onStop = () => stop();
    ever(paused, (_) => update());
    audio.subscriptions.add(
      audio.player.playingStream.listen((p) {
        paused.value = active.value && !p;
      }),
    );
  }

  Future<void> start() async {
    if (active.value || loading.value) return;
    final generation = ++_generation;
    loading.value = true;
    error.value = '';
    result.value = null;
    _finishing = false;
    try {
      final config = BreathingSettings.fromJson(
        settings.settings.value.toJson(),
      );
      engine = BreathingEngine(config, manifest);
      snapshot.value = engine!.at(0);
      // iOS Now Playing uses the audio session; it needs no notification grant.
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
      await audio.prepareSession(config, manifest, manifestText);
      if (generation != _generation) {
        await audio.stop();
        return;
      }
      startedAt = DateTime.now();
      await storage.write('activeSession', {
        'startedAt': startedAt!.toIso8601String(),
        'settings': config.toJson(),
      });
      active.value = true;
      logs.log('Bắt đầu buổi thở ${config.toJson()}');
      _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (engine != null && active.value) {
          snapshot.value = engine!.at(audio.player.position.inMilliseconds);
        }
      });
      await audio.play();
    } catch (e, s) {
      error.value = 'Không mở được âm thanh. Vui lòng thử lại.\n$e';
      logs.log('Lỗi bắt đầu: $e\n$s');
      await stop();
    } finally {
      loading.value = false;
    }
  }

  Future<void> togglePause() async {
    if (!active.value) return;
    if (audio.player.playing) {
      await audio.pause();
    } else {
      await audio.play();
    }
    paused.value = !audio.player.playing;
  }

  Future<void> _complete() async {
    if (!active.value || _finishing || engine == null) return;
    _finishing = true;
    _ticker?.cancel();
    final config = engine!.settings;
    final now = DateTime.now();
    final s = BreathingSession(
      id: startedAt!.microsecondsSinceEpoch.toString(),
      startedAt: startedAt!,
      completedAt: now,
      settings: config,
      completedRounds: config.rounds,
      totalDurationSeconds: (engine!.totalMs / 1000).round(),
      totalHoldSeconds: config.rounds * config.holdSeconds,
    );
    try {
      await sessions.addSession(s);
      await storage.remove('activeSession');
      logs.log('Hoàn thành buổi ${s.id}');
      result.value = s;
    } catch (e) {
      logs.log('Lỗi lưu kết quả: $e');
      error.value = 'Không lưu được kết quả: $e';
    }
    active.value = false;
    audio.onStop = null;
    await audio.stop();
    audio.onStop = () => stop();
  }

  Future<void> stop() async {
    ++_generation;
    _ticker?.cancel();
    final wasActive = active.value;
    active.value = false;
    paused.value = false;
    await storage.remove('activeSession');
    if (wasActive) logs.log('Dừng buổi thở; không ghi hoàn thành');
    if (audio.ready) {
      audio.onStop = null;
      await audio.stop();
      audio.onStop = () => stop();
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
