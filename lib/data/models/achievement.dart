class Achievement {
  final String id, name;
  final int progress, target;
  final DateTime? unlockedAt;
  const Achievement(
    this.id,
    this.name,
    this.progress,
    this.target,
    this.unlockedAt,
  );
  bool get unlocked => progress >= target;
}
