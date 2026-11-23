import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xike_bac_au/core/services/audio_manifest.dart';
import 'package:xike_bac_au/core/services/audio_renderer.dart';
import 'package:xike_bac_au/core/services/breathing_engine.dart';
import 'package:xike_bac_au/core/utils/duration_calculator.dart';
import 'package:xike_bac_au/core/utils/time_formatter.dart';
import 'package:xike_bac_au/data/models/breathing_settings.dart';
import 'package:xike_bac_au/data/models/breathing_session.dart';
import 'package:xike_bac_au/data/models/breath_hold_attempt.dart';
import 'package:xike_bac_au/data/repositories/statistics_repository.dart';

void main() {
  final text = File('assets/am-thanh/lich.txt').readAsStringSync();
  final manifest = AudioManifest.parse(text);
  BreathingSession session(
    int day, {
    int month = 11,
    int year = 2026,
    int hold = 90,
    int seconds = 900,
    int rounds = 3,
  }) => BreathingSession(
    id: '$year-$month-$day',
    startedAt: DateTime(year, month, day, 8),
    completedAt: DateTime(year, month, day, 8, 15),
    settings: BreathingSettings(rounds: rounds, holdSeconds: hold),
    completedRounds: rounds,
    totalDurationSeconds: seconds,
    totalHoldSeconds: rounds * hold,
  );
  test('Metadata matches actual PCM; all offsets in range', () {
    final bytes = File('assets/am-thanh/giong.pcm').lengthSync();
    expect(
      File('assets/am-thanh/nhac.pcm').lengthSync(),
      manifest.musicSamples * 2,
    );
    for (final p in manifest.phrases.values) {
      for (final c in p.cues) {
        expect((c.startSample + c.sampleCount) * 2, lessThanOrEqualTo(bytes));
        expect(
          BreathingEngine.samples(c.offsetMs) + c.sampleCount,
          lessThanOrEqualTo(BreathingEngine.samples(p.durationMs)),
        );
      }
    }
  });
  test('Full timeline duration includes preparation, transitions, outro', () {
    final engine = BreathingEngine(const BreathingSettings(), manifest);
    expect(engine.totalMs, 862010);
    expect(
      engine.stages
          .where((s) => s.phase == BreathingPhase.guidedBreathing)
          .length,
      3,
    );
    expect(
      engine.stages.where((s) => s.phase == BreathingPhase.nextRound).length,
      2,
    );
    expect(engine.at(engine.totalMs).progress, 1);
    expect(
      DurationCalculator(manifest)
          .milliseconds(const BreathingSettings(holdSeconds: 240)),
      1312010,
    );
  });
  test('Every phase boundary and round resolves exactly, even after background jump', () {
    final e = BreathingEngine(const BreathingSettings(rounds: 10), manifest);
    for (final s in e.stages) {
      expect(e.at(s.startMs).stage, s);
      expect(e.at(s.endMs - 1).stage, s);
    }
    expect(e.at(19470).stage.phase, BreathingPhase.guidedBreathing);
    expect(e.at(e.totalMs).stage.phase, BreathingPhase.completed);
    expect(e.at(19470 + 2030).title, 'IN');
    expect(e.at(19470 + 3730).title, 'OUT');
  });
  test('Pause and resume position is deterministic and never advances from repaint', () {
    final e = BreathingEngine(const BreathingSettings(), manifest);
    final paused = e.at(25000);
    for (var i = 0; i < 100; i++) {
      expect(e.at(25000).stageElapsed, paused.stageElapsed);
      expect(e.at(25000).lungs, paused.lungs);
    }
    expect(e.at(27000).stageElapsed, paused.stageElapsed + 2000);
  });
  test(
    'Hold ending and recovery cues never exceed their phases for all settings',
    () {
      for (final hold in [15, 20, 40, 45, 90, 600]) {
        for (final recovery in [5, 8, 15, 40, 60]) {
          final e = BreathingEngine(
            BreathingSettings(holdSeconds: hold, recoverySeconds: recovery),
            manifest,
          );
          for (final v in e.voices) {
            expect(v.sample, greaterThanOrEqualTo(0));
            expect(
              v.sample + v.count,
              lessThanOrEqualTo(BreathingEngine.samples(e.totalMs)),
            );
          }
          for (final s in e.stages.where(
            (s) =>
                s.phase == BreathingPhase.exhaleAndHold ||
                s.phase == BreathingPhase.recoveryHold,
          )) {
            final cues = e.voices.where(
              (v) =>
                  v.sample >= BreathingEngine.samples(s.startMs) &&
                  v.sample < BreathingEngine.samples(s.endMs),
            );
            for (final c in cues) {
              expect(
                c.sample + c.count,
                lessThanOrEqualTo(BreathingEngine.samples(s.endMs)),
              );
            }
          }
        }
      }
    },
  );
  test('Stopwatch and clock format across 60s and one hour', () {
    expect(stopwatchText(0), '0:00,0');
    expect(stopwatchText(45399), '0:45,3');
    expect(stopwatchText(125100), '2:05,1');
    expect(clock(3661), '1:01:01');
    expect(clock(-1), '00:00');
    expect(durationLabel(240), '4 phút');
  });
  test('Settings bounds and JSON roundtrip', () {
    final s = BreathingSettings.fromJson({
      'rounds': 99,
      'holdSeconds': 0,
      'recoverySeconds': 100,
    });
    expect(s.rounds, 10);
    expect(s.holdSeconds, 15);
    expect(s.recoverySeconds, 60);
    expect(BreathingSettings.fromJson(s.toJson()).toJson(), s.toJson());
    final a = BreathHoldAttempt(
      id: 'a',
      createdAt: DateTime(2026),
      durationMilliseconds: 65001,
    );
    expect(BreathHoldAttempt.fromJson(a.toJson()).durationMilliseconds, 65001);
    final b = session(1);
    expect(BreathingSession.fromJson(b.toJson()).toJson(), b.toJson());
  });
  test('Streaks handle duplicates, month boundary, yesterday and gaps', () {
    final r = StatisticsRepository([
      session(30, month: 10),
      session(31, month: 10),
      session(1),
      session(1),
      session(3),
    ]);
    expect(r.longestStreak, 3);
    expect(r.currentStreak(DateTime(2026, 11, 2)), 3);
    expect(r.currentStreak(DateTime(2026, 11, 4)), 1);
    expect(r.currentStreak(DateTime(2026, 11, 5)), 0);
  });
  test('Real totals, records and achievements derive unlock date', () {
    final values = List.generate(20, (i) => session(i + 1, seconds: 900));
    final r = StatisticsRepository(values);
    expect(r.totalSeconds, 18000);
    expect(r.rounds, 60);
    expect(r.record, 90);
    expect(r.achievements.every((a) => a.unlocked), true);
    expect(r.achievements.first.unlockedAt, values.first.completedAt);
    expect(
      r.achievements.firstWhere((a) => a.id == 'hour').unlockedAt,
      values[3].completedAt,
    );
    expect(
      StatisticsRepository([]).achievements.every((a) => !a.unlocked),
      true,
    );
  });
  test('Period filtering: Monday start, leap year, half-open ends', () {
    final now = DateTime(2026, 11, 23);
    final week = DateRange.forPeriod(Period.week, 0, now);
    expect(week.start, DateTime(2026, 11, 23));
    expect(week.end, DateTime(2026, 11, 30));
    expect(week.contains(week.end), false);
    expect(
      DateRange.forPeriod(
        Period.month,
        1,
        DateTime(2024, 3, 1),
      ).end.difference(DateTime(2024, 2, 1)).inDays,
      29,
    );
    expect(
      StatisticsRepository([session(22), session(23), session(30)])
          .within(week)
          .length,
      1,
    );
    expect(DateRange.forPeriod(Period.year, 1, now).start, DateTime(2025));
  });
  test('WAV render is lossless PCM and sample-accurate at voice insertion', () {
    final temp = Directory.systemTemp.createTempSync('xike-audio-test');
    addTearDown(() => temp.deleteSync(recursive: true));
    final path = '${temp.path}/session.wav';
    final voice = File('assets/am-thanh/giong.pcm').readAsBytesSync(),
        music = File('assets/am-thanh/nhac.pcm').readAsBytesSync();
    final e = BreathingEngine(
      const BreathingSettings(rounds: 1, holdSeconds: 15, recoverySeconds: 5),
      manifest,
    );
    renderSessionAudio({
      'path': path,
      'voice': voice,
      'music': music,
      'manifest': text,
      'settings': e.settings.toJson(),
    });
    final f = File(path).openSync();
    addTearDown(f.closeSync);
    final header = ByteData.sublistView(f.readSync(44));
    expect(header.getUint32(24, Endian.little), 22050);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint16(34, Endian.little), 16);
    final count = e.totalSamples;
    expect(File(path).lengthSync(), 44 + count * 2);
    final sample = e.voices.first.sample + 500;
    f.setPositionSync(44 + sample * 2);
    final actual = ByteData.sublistView(f.readSync(2))
        .getInt16(0, Endian.little);
    final vd = ByteData.sublistView(voice), md = ByteData.sublistView(music);
    final cue = e.voices.first;
    final v =
        vd.getInt16((cue.startSample + 500) * 2, Endian.little) /
        32768 *
        manifest.voiceGain *
        32767;
    final m =
        md.getInt16(sample % manifest.musicSamples * 2, Endian.little) /
        32768 *
        manifest.musicGain *
        min(1, min(sample / 44100, (count - sample) / 132300)) *
        32767;
    expect((actual - (m.round() + v).round()).abs(), lessThanOrEqualTo(1));
  });
}
