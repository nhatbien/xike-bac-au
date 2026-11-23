import 'dart:convert';

import 'breath_hold_attempt.dart';
import 'custom_badge.dart';
import 'breathing_session.dart';
import 'breathing_settings.dart';

class TrainingBackup {
  static const format = 'max.xike.hihi.backup';
  static const version = 1;
  static const maxBytes = 20 * 1024 * 1024;

  final List<CustomBadge> customBadges;
  final DateTime exportedAt;
  final BreathingSettings settings;
  final List<BreathingSession> sessions;
  final List<BreathHoldAttempt> attempts;

  TrainingBackup({
    required this.exportedAt,
    required this.settings,
    required Iterable<BreathingSession> sessions,
    required Iterable<BreathHoldAttempt> attempts,
    Iterable<CustomBadge> customBadges = const [],
  }) : sessions = List.unmodifiable(sessions),
       attempts = List.unmodifiable(attempts),
       customBadges = List.unmodifiable(customBadges);

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'format': format,
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'data': {
      'settings': settings.toJson(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'attempts': attempts.map((a) => a.toJson()).toList(),
      'customBadges': customBadges.map((b) => b.toJson()).toList(),
    },
  });

  factory TrainingBackup.decode(String contents) {
    try {
      final root = jsonDecode(contents) as Map<String, dynamic>;
      if (root['format'] != format) {
        throw const FormatException(
          'Đây không phải file sao lưu Xì ke bắc âu.',
        );
      }
      if (root['version'] is! int || root['version'] != version) {
        throw const FormatException(
          'Phiên bản file chưa được hỗ trợ. Hãy cập nhật app.',
        );
      }
      final exportedAt = DateTime.parse(root['exportedAt'] as String);
      final data = root['data'] as Map<String, dynamic>;
      final settings = _settings(data['settings']);
      final sessions = <BreathingSession>[];
      final sessionIds = <String>{};
      for (final value in data['sessions'] as List) {
        final item = value as Map<String, dynamic>;
        _settings(item['settings']);
        final session = BreathingSession.fromJson(item);
        if (session.id.isEmpty ||
            !sessionIds.add(session.id) ||
            !session.isCompleted ||
            session.completedAt.isBefore(session.startedAt) ||
            session.completedRounds < 1 ||
            session.completedRounds > session.settings.rounds ||
            session.totalDurationSeconds < 0 ||
            session.totalHoldSeconds < 0) {
          throw const FormatException('Dữ liệu buổi tập không hợp lệ.');
        }
        sessions.add(session);
      }
      final attempts = <BreathHoldAttempt>[];
      final attemptIds = <String>{};
      for (final value in data['attempts'] as List) {
        final attempt = BreathHoldAttempt.fromJson(
          value as Map<String, dynamic>,
        );
        if (attempt.id.isEmpty ||
            !attemptIds.add(attempt.id) ||
            attempt.durationMilliseconds < 0) {
          throw const FormatException('Dữ liệu nín thở không hợp lệ.');
        }
        attempts.add(attempt);
      }
      final badges = <CustomBadge>[];
      final badgeIds = <String>{};
      final badgeNames = <String>{};
      for (final value in (data['customBadges'] ?? []) as List) {
        final badge = CustomBadge.fromJson(value as Map<String, dynamic>);
        if (!badgeIds.add(badge.id) ||
            !badgeNames.add(badge.name.toLowerCase())) {
          throw const FormatException('File có huy hiệu trùng lặp.');
        }
        badges.add(badge);
      }
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      attempts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return TrainingBackup(
        exportedAt: exportedAt,
        settings: settings,
        sessions: sessions,
        attempts: attempts,
        customBadges: badges,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('File sao lưu bị lỗi hoặc thiếu dữ liệu.');
    }
  }

  static BreathingSettings _settings(dynamic value) {
    final data = value as Map<String, dynamic>;
    final rounds = data['rounds'];
    final hold = data['holdSeconds'];
    final recovery = data['recoverySeconds'];
    if (rounds is! int ||
        rounds < 1 ||
        rounds > 10 ||
        hold is! int ||
        hold < 15 ||
        hold > 600 ||
        recovery is! int ||
        recovery < 5 ||
        recovery > 60 ||
        data['breathsPerRound'] != 40) {
      throw const FormatException('Cài đặt trong file sao lưu không hợp lệ.');
    }
    return BreathingSettings.fromJson(data);
  }
}
