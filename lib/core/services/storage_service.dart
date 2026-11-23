import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  final SharedPreferencesWithCache preferences;
  StorageService(this.preferences);

  static const _prefix = 'xike.v1.';
  static const _trainingKey = '${_prefix}trainingData';
  static const _trainingKeys = {'settings', 'sessions', 'attempts'};

  Map<String, dynamic>? _trainingData() {
    final value = preferences.getString(_trainingKey);
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  T? read<T>(String key) {
    if (_trainingKeys.contains(key)) {
      final data = _trainingData();
      if (data != null) return data[key] as T?;
    }
    final encoded = preferences.getString('$_prefix$key');
    return encoded == null ? null : jsonDecode(encoded) as T?;
  }

  Future<void> write(String key, dynamic value) async {
    if (_trainingKeys.contains(key)) {
      final data = _trainingData();
      if (data != null) {
        data[key] = value;
        await preferences.setString(_trainingKey, jsonEncode(data));
        return;
      }
    }
    // Encode maps/lists as JSON because preferences only supports simple types.
    await preferences.setString('$_prefix$key', jsonEncode(value));
  }

  Future<void> remove(String key) async {
    if (_trainingKeys.contains(key)) {
      final data = _trainingData();
      if (data != null) {
        data.remove(key);
        await preferences.setString(_trainingKey, jsonEncode(data));
        return;
      }
    }
    await preferences.remove('$_prefix$key');
  }

  /// Import all three collections with one platform write, so a partial
  /// restore cannot mix new settings with old history. Other device data stays.
  Future<void> replaceTrainingData({
    required Map<String, dynamic> settings,
    required List<Map<String, dynamic>> sessions,
    required List<Map<String, dynamic>> attempts,
  }) async {
    final previous = preferences.getString(_trainingKey);
    try {
      await preferences.setString(
        _trainingKey,
        jsonEncode({
          'settings': settings,
          'sessions': sessions,
          'attempts': attempts,
        }),
      );
    } catch (_) {
      // The cache updates before the platform write. Restore the previous
      // value as well, so the current UI can keep using the original data.
      try {
        if (previous == null) {
          await preferences.remove(_trainingKey);
        } else {
          await preferences.setString(_trainingKey, previous);
        }
      } catch (_) {
        await preferences.reloadCache();
      }
      rethrow;
    }
  }
}
