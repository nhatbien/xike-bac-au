class BreathingSettings {
  final int rounds, holdSeconds, recoverySeconds, breathsPerRound;
  const BreathingSettings({
    this.rounds = 3,
    this.holdSeconds = 90,
    this.recoverySeconds = 40,
    this.breathsPerRound = 40,
  });
  factory BreathingSettings.fromJson(Map<String, dynamic> j) =>
      BreathingSettings(
        rounds: (j['rounds'] as int? ?? 3).clamp(1, 10),
        holdSeconds: (j['holdSeconds'] as int? ?? 90).clamp(15, 600),
        recoverySeconds: (j['recoverySeconds'] as int? ?? 40).clamp(5, 60),
      );
  Map<String, dynamic> toJson() => {
    'rounds': rounds,
    'holdSeconds': holdSeconds,
    'recoverySeconds': recoverySeconds,
    'breathsPerRound': breathsPerRound,
  };
  BreathingSettings copyWith({
    int? rounds,
    int? holdSeconds,
    int? recoverySeconds,
  }) => BreathingSettings(
    rounds: rounds ?? this.rounds,
    holdSeconds: holdSeconds ?? this.holdSeconds,
    recoverySeconds: recoverySeconds ?? this.recoverySeconds,
  );
}
