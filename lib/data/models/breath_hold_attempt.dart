class BreathHoldAttempt {
  final String id;
  final DateTime createdAt;
  final int durationMilliseconds;
  const BreathHoldAttempt({
    required this.id,
    required this.createdAt,
    required this.durationMilliseconds,
  });
  factory BreathHoldAttempt.fromJson(Map<String, dynamic> j) =>
      BreathHoldAttempt(
        id: j['id'],
        createdAt: DateTime.parse(j['createdAt']),
        durationMilliseconds: j['durationMilliseconds'],
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'durationMilliseconds': durationMilliseconds,
  };
}
