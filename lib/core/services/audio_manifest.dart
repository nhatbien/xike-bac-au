class VoiceCue {
  final int offsetMs, startSample, sampleCount;
  final String label;
  const VoiceCue(this.offsetMs, this.startSample, this.sampleCount, this.label);
}

class AudioPhrase {
  final String name;
  final int durationMs;
  final List<VoiceCue> cues;
  AudioPhrase(this.name, this.durationMs, this.cues);
}

class AudioManifest {
  final Map<String, AudioPhrase> phrases;
  final int musicSamples;
  final double voiceGain, musicGain;
  const AudioManifest(
    this.phrases,
    this.musicSamples,
    this.voiceGain,
    this.musicGain,
  );
  factory AudioManifest.parse(String text) {
    final phrases = <String, AudioPhrase>{};
    AudioPhrase? current;
    int music = 0;
    double vg = 0, mg = 0;
    for (final line in text.split('\n')) {
      final p = line.trim().split('\t');
      if (p.isEmpty || p[0].startsWith('#')) continue;
      switch (p[0]) {
        case 'nhac':
          music = int.parse(p[1]);
        case 'tron':
          vg = double.parse(p[1]);
          mg = double.parse(p[2]);
        case 'cau':
          current = AudioPhrase(p[1], int.parse(p[2]), []);
          phrases[p[1]] = current;
        case 'dat':
          current!.cues.add(
            VoiceCue(int.parse(p[1]), int.parse(p[2]), int.parse(p[3]), p[4]),
          );
      }
    }
    if (music <= 0 || vg <= 0 || phrases.isEmpty) {
      throw const FormatException('Lịch âm thanh không hợp lệ');
    }
    return AudioManifest(phrases, music, vg, mg);
  }
}
