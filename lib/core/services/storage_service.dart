import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  final GetStorage box;
  StorageService(this.box);
  T? read<T>(String key) => box.read<T>(key);
  Future<void> write(String key, dynamic value) async {
    await box.write(key, value);
    // GetStorage.write schedules its flush in a microtask. Wait for the queue
    // barrier as well before treating a session or its marker as persisted.
    await box.queue.add(() async {});
  }

  Future<void> remove(String key) async {
    await box.remove(key);
    await box.queue.add(() async {});
  }
}
