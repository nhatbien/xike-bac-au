import 'dart:math';

import '../../data/models/breathing_settings.dart';
import 'audio_manifest.dart';

enum BreathingPhase {
  preparing,
  guidedBreathing,
  exhaleAndHold,
  recoveryHold,
  nextRound,
  completed,
}

class TimelineStage {
  final BreathingPhase phase;
  final int round, startMs, durationMs;
  final String phrase;
  final int startSample;
  int get endSample => startSample + BreathingEngine.samples(durationMs);
  const TimelineStage(
    this.phase,
    this.round,
    this.startMs,
    this.durationMs,
    this.phrase, {
    required this.startSample,
  });
  int get endMs => startMs + durationMs;
}

class ScheduledVoice {
  final int sample, startSample, count;
  const ScheduledVoice(this.sample, this.startSample, this.count);
}

class BreathingSnapshot {
  final TimelineStage stage;
  final int elapsedMs, totalMs;
  final double lungs;
  const BreathingSnapshot(this.stage, this.elapsedMs, this.totalMs, this.lungs);
  int get stageElapsed =>
      (elapsedMs - stage.startMs).clamp(0, stage.durationMs);
  int get remainingSeconds => max(0, ((totalMs - elapsedMs) / 1000).ceil());
  double get progress => (elapsedMs / totalMs).clamp(0, 1);
  int get breath => (((stageElapsed - 2000) / 3260).floor() + 1).clamp(1, 40);
  String get title => switch (stage.phase) {
    BreathingPhase.preparing => 'Ngồi thoải mái',
    BreathingPhase.guidedBreathing =>
      stageElapsed < 2000
          ? 'Chuẩn bị thở'
          : stageElapsed >= 132400
          ? 'Thở ra hết · nín'
          : ((stageElapsed - 2000) % 3260 < 1700 ? 'IN' : 'OUT'),
    BreathingPhase.exhaleAndHold => _clock(
      ((stage.durationMs - stageElapsed) / 1000).ceil(),
    ),
    BreathingPhase.recoveryHold => _clock(
      ((stage.durationMs - stageElapsed) / 1000).ceil(),
    ),
    BreathingPhase.nextRound => 'Thả ra',
    BreathingPhase.completed => 'Tuyệt vời!',
  };
  static String _clock(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class BreathingEngine {
  final BreathingSettings settings;
  final AudioManifest manifest;
  final stages = <TimelineStage>[];
  final voices = <ScheduledVoice>[];
  int get totalMs => stages.last.endMs;
  int get totalSamples => stages.last.endSample;
  static int samples(int ms) => ms * 441 ~/ 20;
  BreathingEngine(this.settings, this.manifest) {
    _build();
  }
  void _build() {
    int t = 0;
    int sampleCursor = 0;
    void add(BreathingPhase p, int round, String phrase, [int? duration]) {
      final d = duration ?? manifest.phrases[phrase]!.durationMs;
      stages.add(
        TimelineStage(p, round, t, d, phrase, startSample: sampleCursor),
      );
      t += d;
      sampleCursor += samples(d);
    }

    add(BreathingPhase.preparing, 1, 'bat-dau');
    for (var i = 1; i <= settings.rounds; i++) {
      add(BreathingPhase.guidedBreathing, i, 'tho-${(i - 1) % 3 + 1}');
      add(BreathingPhase.exhaleAndHold, i, 'nin', settings.holdSeconds * 1000);
      add(
        BreathingPhase.recoveryHold,
        i,
        'hit-vao',
        settings.recoverySeconds * 1000,
      );
      if (i < settings.rounds) {
        add(BreathingPhase.nextRound, i + 1, 'tha-ra-${i + 1}');
      }
    }
    add(BreathingPhase.completed, settings.rounds, 'xong');
    for (final stage in stages) {
      void phrase(
        String name,
        int offsetMs, {
        int? cutoffSample,
        int? offsetSamples,
      }) {
        for (final c in manifest.phrases[name]!.cues) {
          final local =
              (offsetSamples ?? samples(offsetMs)) + samples(c.offsetMs);
          if (cutoffSample == null || local + c.sampleCount <= cutoffSample) {
            voices.add(
              ScheduledVoice(
                stage.startSample + local,
                c.startSample,
                c.sampleCount,
              ),
            );
          }
        }
      }

      if (stage.phase == BreathingPhase.exhaleAndHold) {
        final n = settings.holdSeconds;
        final ending = n >= 45
            ? 'nin-cuoi-30'
            : n >= 20
            ? 'nin-cuoi-10'
            : null;
        final endMs = ending == null ? 0 : manifest.phrases[ending]!.durationMs;
        phrase(
          'nin',
          0,
          cutoffSample: samples(stage.durationMs) - samples(endMs) - 22050,
        );
        if (ending != null) {
          phrase(
            ending,
            stage.durationMs - endMs,
            offsetSamples: samples(stage.durationMs) - samples(endMs),
          );
        }
      } else if (stage.phase == BreathingPhase.recoveryHold) {
        final ending = settings.recoverySeconds >= 8;
        final endMs = ending ? manifest.phrases['giu-cuoi']!.durationMs : 0;
        phrase(
          'hit-vao',
          0,
          cutoffSample: samples(stage.durationMs) - samples(endMs) - 2205,
        );
        if (ending) {
          phrase(
            'giu-cuoi',
            stage.durationMs - endMs,
            offsetSamples: samples(stage.durationMs) - samples(endMs),
          );
        }
      } else {
        phrase(stage.phrase, 0);
      }
    }
    voices.sort((a, b) => a.sample.compareTo(b.sample));
  }

  BreathingSnapshot at(int positionMs) {
    final ms = positionMs.clamp(0, totalMs);
    final stage = stages.firstWhere(
      (s) => ms < s.endMs,
      orElse: () => stages.last,
    );
    final local = ms - stage.startMs;
    double lungs = .3;
    double smooth(double x) {
      final t = x.clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    switch (stage.phase) {
      case BreathingPhase.preparing:
        lungs = .35 + sin(local / 1000 * 2 * pi / 6) * .15;
      case BreathingPhase.guidedBreathing:
        if (local < 2000) {
          lungs = .3 - smooth(local / 2000) * .15;
        } else if (local >= 132400) {
          lungs = max(0, (1 - smooth((local - 132400) / 1200)) * .15);
        } else {
          final p = (local - 2000) % 3260;
          lungs = p < 1700
              ? .15 + .85 * smooth(p / 1700)
              : 1 - .85 * smooth((p - 1700) / 1560);
        }
      case BreathingPhase.exhaleAndHold:
        lungs = 0;
      case BreathingPhase.recoveryHold:
        lungs = smooth(local / 2500);
      case BreathingPhase.nextRound:
      case BreathingPhase.completed:
        lungs = 1 - .7 * smooth(local / 2000);
    }
    return BreathingSnapshot(stage, ms, totalMs, lungs.clamp(0, 1));
  }
}
