class CustomBadge {
  final String id;
  final String name;
  final int points;
  final DateTime createdAt;

  CustomBadge({
    required this.id,
    required String name,
    required this.points,
    required this.createdAt,
  }) : name = name.trim() {
    if (id.isEmpty ||
        this.name.isEmpty ||
        this.name.length > 60 ||
        points < 1 ||
        points > 9999) {
      throw const FormatException(
        'Huy hiệu cần tên từ 1–60 ký tự và điểm từ 1–9999.',
      );
    }
  }

  factory CustomBadge.fromJson(Map<String, dynamic> json) => CustomBadge(
    id: json['id'] as String,
    name: json['name'] as String,
    points: json['points'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'points': points,
    'createdAt': createdAt.toIso8601String(),
  };
}
