import 'breathing_settings.dart';

class BreathingSession {
  final String id;
  final DateTime startedAt, completedAt;
  final BreathingSettings settings;
  final int completedRounds, totalDurationSeconds, totalHoldSeconds;
  final bool isCompleted;
  const BreathingSession({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.settings,
    required this.completedRounds,
    required this.totalDurationSeconds,
    required this.totalHoldSeconds,
    this.isCompleted = true,
  });
  int get recoverySeconds => settings.recoverySeconds;
  factory BreathingSession.fromJson(Map<String, dynamic> j) => BreathingSession(
    id: j['id'],
    startedAt: DateTime.parse(j['startedAt']),
    completedAt: DateTime.parse(j['completedAt']),
    settings: BreathingSettings.fromJson(
      Map<String, dynamic>.from(j['settings']),
    ),
    completedRounds: j['completedRounds'],
    totalDurationSeconds: j['totalDurationSeconds'],
    totalHoldSeconds: j['totalHoldSeconds'],
    isCompleted: j['isCompleted'] ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'settings': settings.toJson(),
    'completedRounds': completedRounds,
    'totalDurationSeconds': totalDurationSeconds,
    'totalHoldSeconds': totalHoldSeconds,
    'isCompleted': isCompleted,
  };
}
