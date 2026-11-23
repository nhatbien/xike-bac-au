import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../data/models/breathing_settings.dart';
import 'audio_manifest.dart';
import 'breathing_engine.dart';

// Runs in a worker isolate. Blocks keep peak memory independent of session length.
String renderSessionAudio(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final voice = ByteData.sublistView(args['voice'] as Uint8List);
  final music = ByteData.sublistView(args['music'] as Uint8List);
  final manifest = AudioManifest.parse(args['manifest'] as String);
  if (music.lengthInBytes != manifest.musicSamples * 2) {
    throw const FormatException('Độ dài nhạc không khớp metadata');
  }
  final engine = BreathingEngine(
    BreathingSettings.fromJson(args['settings']),
    manifest,
  );
  for (final c in engine.voices) {
    if ((c.startSample + c.count) * 2 > voice.lengthInBytes) {
      throw const FormatException('Sample giọng nằm ngoài PCM');
    }
  }
  final count = engine.totalSamples;
  final header = ByteData(44);
  void str(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  header.setUint32(4, 36 + count * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, 22050, Endian.little);
  header.setUint32(28, 44100, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  str(36, 'data');
  header.setUint32(40, count * 2, Endian.little);
  final temporary = File('$path.partial');
  final file = temporary.openSync(mode: FileMode.write);
  try {
    file.writeFromSync(header.buffer.asUint8List());
    var first = 0;
    for (var base = 0; base < count; base += 16384) {
      final n = min(16384, count - base);
      final block = ByteData(n * 2);
      final mixed = Float64List(n);
      for (var i = 0; i < n; i++) {
        final sample = base + i;
        final fade = min(1.0, min(sample / 44100, (count - sample) / 132300));
        final v =
            music.getInt16(sample % manifest.musicSamples * 2, Endian.little) /
            32768 *
            manifest.musicGain *
            fade;
        mixed[i] = v * 32767;
      }
      while (first < engine.voices.length &&
          engine.voices[first].sample + engine.voices[first].count <= base) {
        first++;
      }
      for (
        var j = first;
        j < engine.voices.length && engine.voices[j].sample < base + n;
        j++
      ) {
        final cue = engine.voices[j];
        for (
          var sample = max(base, cue.sample);
          sample < min(base + n, cue.sample + cue.count);
          sample++
        ) {
          final off = sample - base;
          final v =
              voice.getInt16(
                (cue.startSample + sample - cue.sample) * 2,
                Endian.little,
              ) /
              32768 *
              manifest.voiceGain *
              32767;
          mixed[off] += v;
        }
      }
      for (var i = 0; i < n; i++) {
        block.setInt16(
          i * 2,
          mixed[i].round().clamp(-32768, 32767),
          Endian.little,
        );
      }
      file.writeFromSync(block.buffer.asUint8List());
    }
    file.flushSync();
  } finally {
    file.closeSync();
  }
  temporary.renameSync(path);
  return path;
}
