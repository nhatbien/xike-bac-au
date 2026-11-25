import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/breathing_settings.dart';
import 'audio_manifest.dart';
import 'audio_renderer.dart';
import 'logging_service.dart';

class TrainingAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer(handleInterruptions: false);
  final LoggingService logs;
  final subscriptions = <StreamSubscription>[];
  void Function()? onComplete, onStop;
  bool ready = false;
  bool _resumeOnFocus = false;
  TrainingAudioHandler(this.logs) {
    subscriptions.add(
      player.playbackEventStream.listen(
        (event) {
          playbackState.add(
            PlaybackState(
              controls: [
                player.playing ? MediaControl.pause : MediaControl.play,
                MediaControl.stop,
              ],
              systemActions: const {},
              androidCompactActionIndices: const [0, 1],
              processingState: switch (player.processingState) {
                ProcessingState.idle => AudioProcessingState.idle,
                ProcessingState.loading => AudioProcessingState.loading,
                ProcessingState.buffering => AudioProcessingState.buffering,
                ProcessingState.ready => AudioProcessingState.ready,
                ProcessingState.completed => AudioProcessingState.completed,
              },
              playing: player.playing,
              updatePosition: player.position,
              bufferedPosition: player.bufferedPosition,
              speed: player.speed,
            ),
          );
        },
        onError: (Object e, StackTrace s) {
          logs.log('Lỗi playback: $e');
          onStop?.call();
        },
      ),
    );
    subscriptions.add(
      player.processingStateStream.listen((s) {
        if (s == ProcessingState.completed && ready) onComplete?.call();
      }),
    );
  }
  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    subscriptions.add(
      session.interruptionEventStream.listen((e) async {
        if (e.begin) {
          _resumeOnFocus = player.playing;
          await pause();
          logs.log('Âm thanh bị gián đoạn: ${e.type.name}');
        } else if (_resumeOnFocus && e.type == AudioInterruptionType.pause) {
          _resumeOnFocus = false;
          await play();
        }
      }),
    );
    subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        _resumeOnFocus = false;
        pause();
        logs.log('Rút tai nghe: tạm dừng');
      }),
    );
  }

  Future<void> prepareSession(
    BreathingSettings settings,
    AudioManifest manifest,
    String manifestText,
  ) async {
    ready = false;
    final cache = await getTemporaryDirectory();
    // System media controls need a real file URI, not a Flutter asset path.
    final artwork = File('${cache.path}/xike-now-playing.png');
    final artworkData = await rootBundle.load('assets/now_playing.png');
    await artwork.writeAsBytes(
      artworkData.buffer.asUint8List(
        artworkData.offsetInBytes,
        artworkData.lengthInBytes,
      ),
      flush: true,
    );
    final path =
        '${cache.path}/xike-v3-${settings.voice.id}-${settings.rounds}-${settings.holdSeconds}-${settings.recoverySeconds}.wav';
    if (!File(path).existsSync()) {
      final data = await Future.wait([
        rootBundle.load(settings.voice.audioAsset),
        rootBundle.load('assets/am-thanh/nhac.pcm'),
      ]);
      logs.log('Dựng WAV lossless 22050Hz mono');
      await compute(renderSessionAudio, {
        'path': path,
        'voice': data[0].buffer.asUint8List(),
        'music': data[1].buffer.asUint8List(),
        'manifest': manifestText,
        'settings': settings.toJson(),
      });
    }
    mediaItem.add(
      MediaItem(
        id: path,
        title: 'Thở cùng ${settings.voice.label}',
        album: 'Ìe Bắc Âu',
        artUri: artwork.uri,
        duration: null,
      ),
    );
    final duration = await player.setFilePath(path);
    mediaItem.add(mediaItem.value!.copyWith(duration: duration));
    ready = true;
    logs.log('Nạp âm thanh thành công: ${duration?.inMilliseconds}ms');
    // Keep only the current render. Long sessions may consume hundreds of MB.
    for (final entry in cache.listSync()) {
      if (entry is File &&
          (entry.path.contains('/xike-v2-') ||
              entry.path.contains('/xike-v3-')) &&
          entry.path != path) {
        try {
          entry.deleteSync();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> play() async {
    if (!ready) return;
    logs.log('Tiếp tục / phát âm thanh');
    unawaited(
      player.play().catchError((Object e) {
        logs.log('Không phát được âm thanh: $e');
        onStop?.call();
      }),
    );
  }

  @override
  Future<void> pause() async {
    await player.pause();
    logs.log('Tạm dừng âm thanh');
  }

  @override
  Future<void> seek(Duration position) async {} // Session order cannot be skipped from media controls.
  @override
  Future<void> stop() async {
    ready = false;
    await player.stop();
    await super.stop();
    onStop?.call();
  }

  Future<void> dispose() async {
    for (final s in subscriptions) {
      await s.cancel();
    }
    await player.dispose();
  }
}
