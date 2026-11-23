import 'package:get/get.dart';

import '../../core/services/storage_service.dart';
import '../../core/services/logging_service.dart';
import '../models/breathing_settings.dart';

class SettingsRepository extends GetxService {
  final StorageService storage;
  final LoggingService logs;
  late final Rx<BreathingSettings> settings;
  SettingsRepository(this.storage, this.logs) {
    settings = BreathingSettings.fromJson(
      Map<String, dynamic>.from(storage.read<Map>('settings') ?? {}),
    ).obs;
  }
  Future<void> save(BreathingSettings value) async {
    settings.value = value;
    await storage.write('settings', value.toJson());
    logs.log('Cài đặt: ${value.toJson()}');
  }
}
