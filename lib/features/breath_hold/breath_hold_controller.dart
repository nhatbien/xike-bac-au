import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/services/logging_service.dart';
import '../../data/models/breath_hold_attempt.dart';
import '../../data/repositories/session_repository.dart';

class BreathHoldController extends GetxController {
  final SessionRepository repository;
  final LoggingService logs;
  BreathHoldController(this.repository, this.logs);
  final elapsed = 0.obs,
      running = false.obs,
      finished = false.obs,
      newRecord = false.obs;
  final Stopwatch watch = Stopwatch();
  Timer? _timer;
  DateTime? startedAt;
  String? lastId;
  int get record => repository.attempts.fold(
    0,
    (m, a) => a.durationMilliseconds > m ? a.durationMilliseconds : m,
  );
  Future<void> tap() async {
    HapticFeedback.lightImpact();
    if (running.value) {
      watch.stop();
      _timer?.cancel();
      elapsed.value = watch.elapsedMilliseconds;
      running.value = false;
      finished.value = true;
      newRecord.value = elapsed.value > record;
      // The original UI treats accidental taps under one second as invalid attempts.
      if (elapsed.value >= 1000) {
        lastId = startedAt!.microsecondsSinceEpoch.toString();
        await repository.addAttempt(
          BreathHoldAttempt(
            id: lastId!,
            createdAt: startedAt!,
            durationMilliseconds: elapsed.value,
          ),
        );
      }
      logs.log('Kết thúc nín thở vui: ${elapsed.value}ms');
    } else {
      startedAt = DateTime.now();
      watch.reset();
      watch.start();
      elapsed.value = 0;
      finished.value = false;
      newRecord.value = false;
      running.value = true;
      logs.log('Bắt đầu nín thở vui');
      _timer = Timer.periodic(
        const Duration(milliseconds: 33),
        (_) => elapsed.value = watch.elapsedMilliseconds,
      );
    }
  }

  Future<void> deleteLast() async {
    if (lastId != null) await repository.deleteAttempt(lastId!);
    lastId = null;
    elapsed.value = 0;
    finished.value = false;
    newRecord.value = false;
  }

  @override
  void onClose() {
    _timer?.cancel();
    if (running.value) {
      watch.stop();
      final ms = watch.elapsedMilliseconds;
      if (ms >= 1000 && startedAt != null) {
        repository.addAttempt(
          BreathHoldAttempt(
            id: startedAt!.microsecondsSinceEpoch.toString(),
            createdAt: startedAt!,
            durationMilliseconds: ms,
          ),
        );
      }
      logs.log('Kết thúc nín thở vui khi rời màn hình: ${ms}ms');
    }
    super.onClose();
  }
}
