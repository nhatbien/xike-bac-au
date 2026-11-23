import 'package:get/get.dart';

import '../../data/models/training_backup.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'storage_service.dart';

class BackupService extends GetxService {
  final StorageService storage;
  final SettingsRepository settings;
  final SessionRepository history;
  BackupService(this.storage, this.settings, this.history);

  TrainingBackup snapshot() => TrainingBackup(
    exportedAt: DateTime.now(),
    settings: settings.settings.value,
    sessions: history.sessions,
    attempts: history.attempts,
    customBadges: history.customBadges,
  );

  Future<void> restore(TrainingBackup backup) async {
    await storage.replaceTrainingData(
      settings: backup.settings.toJson(),
      sessions: backup.sessions.map((s) => s.toJson()).toList(),
      attempts: backup.attempts.map((a) => a.toJson()).toList(),
      customBadges: backup.customBadges.map((b) => b.toJson()).toList(),
    );
    // Publish only after the full snapshot has been saved successfully.
    settings.settings.value = backup.settings;
    history.sessions.assignAll(backup.sessions);
    history.attempts.assignAll(backup.attempts);
    history.customBadges.assignAll(backup.customBadges);
  }
}
