import 'package:get/get.dart';

import 'storage_service.dart';

class LoggingService extends GetxService {
  final StorageService storage;
  final entries = <String>[].obs;
  LoggingService(this.storage) {
    entries.assignAll((storage.read<List>('logs') ?? []).cast<String>());
  }
  void log(String event) {
    entries.add('${DateTime.now().toIso8601String()}  $event');
    if (entries.length > 300) {
      entries.removeRange(0, entries.length - 300);
    }
    storage.write('logs', entries.toList());
  }
}
