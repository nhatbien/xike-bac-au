enum GuidanceVoice {
  original('goc', 'Gốc (Wim Hof)', ''),
  ruoc('bac', 'Ruốc', '-bac'),
  chaBong('nam', 'Chà Bông', '-nam');

  final String id, label, suffix;
  const GuidanceVoice(this.id, this.label, this.suffix);
  String get audioAsset => 'assets/am-thanh/giong$suffix.pcm';
  String get manifestAsset => 'assets/am-thanh/lich$suffix.txt';
  static GuidanceVoice fromId(Object? id) =>
      values.firstWhere((voice) => voice.id == id, orElse: () => original);
}

class BreathingSettings {
  final GuidanceVoice voice;
  final int rounds, holdSeconds, recoverySeconds, breathsPerRound;
  const BreathingSettings({
    this.voice = GuidanceVoice.original,
    this.rounds = 3,
    this.holdSeconds = 90,
    this.recoverySeconds = 40,
    this.breathsPerRound = 40,
  });
  factory BreathingSettings.fromJson(Map<String, dynamic> j) =>
      BreathingSettings(
        voice: GuidanceVoice.fromId(j['voice']),
        rounds: (j['rounds'] as int? ?? 3).clamp(1, 10),
        holdSeconds: (j['holdSeconds'] as int? ?? 90).clamp(15, 600),
        recoverySeconds: (j['recoverySeconds'] as int? ?? 40).clamp(5, 60),
      );
  Map<String, dynamic> toJson() => {
    'voice': voice.id,
    'rounds': rounds,
    'holdSeconds': holdSeconds,
    'recoverySeconds': recoverySeconds,
    'breathsPerRound': breathsPerRound,
  };
  BreathingSettings copyWith({
    GuidanceVoice? voice,
    int? rounds,
    int? holdSeconds,
    int? recoverySeconds,
  }) => BreathingSettings(
    voice: voice ?? this.voice,
    rounds: rounds ?? this.rounds,
    holdSeconds: holdSeconds ?? this.holdSeconds,
    recoverySeconds: recoverySeconds ?? this.recoverySeconds,
  );
}
