import '../../data/models/breathing_settings.dart';
import '../services/audio_manifest.dart';
import '../services/breathing_engine.dart';
import 'time_formatter.dart';

class DurationCalculator {
  final AudioManifest manifest;
  final Map<GuidanceVoice, AudioManifest> voiceManifests;
  const DurationCalculator(this.manifest, {this.voiceManifests = const {}});
  int milliseconds(BreathingSettings s) =>
      BreathingEngine(s, voiceManifests[s.voice] ?? manifest).totalMs;
  int minutes(BreathingSettings s) => (milliseconds(s) / 60000).floor();
  String summary(BreathingSettings s) =>
      '${s.rounds} hiệp · nín ${clock(s.holdSeconds)} · giữ ${s.recoverySeconds} giây';
  String estimate(BreathingSettings s) =>
      'Một buổi dài khoảng ${minutes(s)} phút, nín tổng ${durationLabel(s.rounds * s.holdSeconds)}.';
}
