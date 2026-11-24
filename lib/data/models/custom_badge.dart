import '../../core/utils/time_formatter.dart';

enum BadgeMetric {
  hold('hold', 'Nín thở', 'giây', 60),
  streak('streak', 'Chuỗi ngày liên tiếp', 'ngày', 3),
  sessions('first', 'Số buổi tập', 'buổi', 10),
  trainingTime('hour', 'Tổng thời gian tập', 'phút', 60),
  rounds('rounds', 'Số hiệp', 'hiệp', 50);

  final String key, label, unit;
  final int defaultTarget;
  const BadgeMetric(this.key, this.label, this.unit, this.defaultTarget);

  int toStoredTarget(int value) => this == trainingTime ? value * 60 : value;

  String title(int target) => switch (this) {
    hold => 'Nín thở ${clock(target)}',
    streak => 'Chuỗi $target ngày',
    sessions => '$target buổi tập',
    trainingTime =>
      target % 3600 == 0
          ? '${target ~/ 3600} giờ tập'
          : '${target ~/ 60} phút tập',
    rounds => '$target hiệp',
  };
}

class CustomBadge {
  final String id;
  final BadgeMetric metric;
  final int target;
  final DateTime createdAt;
  // Preserve names from the earlier point-based format when loading old data.
  final String? _legacyName;
  String get name => _legacyName ?? metric.title(target);

  CustomBadge({
    required this.id,
    required this.metric,
    required this.target,
    required this.createdAt,
    String? legacyName,
  }) : _legacyName = legacyName {
    if (id.isEmpty ||
        target < 1 ||
        target > 599940 ||
        (legacyName != null &&
            (legacyName.trim().isEmpty || legacyName.length > 60))) {
      throw const FormatException('Mục tiêu huy hiệu không hợp lệ.');
    }
  }

  factory CustomBadge.fromJson(Map<String, dynamic> json) {
    final legacy = !json.containsKey('metric');
    return CustomBadge(
      id: json['id'] as String,
      metric: legacy
          ? BadgeMetric.sessions
          : BadgeMetric.values.byName(json['metric'] as String),
      target: (legacy ? json['points'] : json['target']) as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      legacyName: legacy
          ? json['name'] as String
          : json['legacyName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'metric': metric.name,
    'target': target,
    'createdAt': createdAt.toIso8601String(),
    if (_legacyName != null) 'legacyName': _legacyName,
  };
}
