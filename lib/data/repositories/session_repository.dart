import 'package:get/get.dart';

import '../../core/services/storage_service.dart';
import '../../core/services/logging_service.dart';
import '../models/breathing_session.dart';
import '../models/custom_badge.dart';
import '../models/breath_hold_attempt.dart';

class SessionRepository extends GetxService {
  final StorageService storage;
  final LoggingService logs;
  final sessions = <BreathingSession>[].obs;
  final attempts = <BreathHoldAttempt>[].obs;
  final customBadges = <CustomBadge>[].obs;
  SessionRepository(this.storage, this.logs) {
    for (final j in storage.read<List>('sessions') ?? []) {
      try {
        sessions.add(BreathingSession.fromJson(Map<String, dynamic>.from(j)));
      } catch (e) {
        logs.log('Bỏ qua bản ghi buổi lỗi: $e');
      }
    }
    for (final j in storage.read<List>('attempts') ?? []) {
      try {
        attempts.add(BreathHoldAttempt.fromJson(Map<String, dynamic>.from(j)));
      } catch (e) {
        logs.log('Bỏ qua lần thử lỗi: $e');
      }
    }
    for (final j in storage.read<List>('customBadges') ?? []) {
      try {
        final badge = CustomBadge.fromJson(Map<String, dynamic>.from(j));
        if (!customBadges.any((b) => b.id == badge.id)) customBadges.add(badge);
      } catch (e) {
        logs.log('Bỏ qua huy hiệu lỗi: $e');
      }
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    attempts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  Future<void> addBadge(String name, int points) async {
    if (customBadges.any(
      (b) => b.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      throw const FormatException('Bạn đã có huy hiệu mang tên này.');
    }
    final now = DateTime.now();
    final badge = CustomBadge(
      id: 'custom-${now.microsecondsSinceEpoch}',
      name: name,
      points: points,
      createdAt: now,
    );
    final updated = [badge, ...customBadges];
    await storage.write(
      'customBadges',
      updated.map((b) => b.toJson()).toList(),
    );
    customBadges.assignAll(updated);
  }

  Future<void> deleteBadge(String id) async {
    final updated = customBadges.where((b) => b.id != id).toList();
    await storage.write(
      'customBadges',
      updated.map((b) => b.toJson()).toList(),
    );
    customBadges.assignAll(updated);
  }

  Future<void> addSession(BreathingSession s) async {
    if (!s.isCompleted || sessions.any((x) => x.id == s.id)) return;
    sessions.insert(0, s);
    await storage.write('sessions', sessions.map((s) => s.toJson()).toList());
  }

  Future<void> deleteSession(String id) async {
    sessions.removeWhere((s) => s.id == id);
    await storage.write('sessions', sessions.map((s) => s.toJson()).toList());
    logs.log('Xoá buổi $id');
  }

  Future<void> addAttempt(BreathHoldAttempt a) async {
    attempts.insert(0, a);
    await storage.write('attempts', attempts.map((a) => a.toJson()).toList());
  }

  Future<void> deleteAttempt(String id) async {
    attempts.removeWhere((a) => a.id == id);
    await storage.write('attempts', attempts.map((a) => a.toJson()).toList());
    logs.log('Xoá lần thử $id');
  }
}
