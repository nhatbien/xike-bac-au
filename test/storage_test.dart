import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xike_bac_au/core/services/storage_service.dart';

class PreferenceWriteControl {
  Completer<void>? pendingWrite;
  Object? failure;
}

class TestPreferences implements SharedPreferencesWithCache {
  final values = <String, String>{};
  final control = PreferenceWriteControl();

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async {
    if (control.failure != null) throw control.failure!;
    await control.pendingWrite?.future;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'JSON preferences restore nested app data, primitives and deletions',
    () async {
      final preferences = TestPreferences();
      final storage = StorageService(preferences);
      final values = <String, dynamic>{
        'settings': {'rounds': 3, 'holdSeconds': 90},
        'sessions': [
          {'id': 'session-1', 'completed': true},
        ],
        'attempts': [
          {'durationMilliseconds': 1234},
        ],
        'logs': ['Mở app', 'Hoàn thành'],
        'activeSession': {'startedAt': '2026-11-24T10:00:00Z'},
        'activatedInviteCode': 'chuotbu',
        'safetyAcknowledgementVersion': 1,
        'boolean': true,
        'decimal': 1.5,
        'null': null,
      };
      for (final entry in values.entries) {
        await storage.write(entry.key, entry.value);
      }
      final restored = StorageService(preferences);
      for (final entry in values.entries) {
        expect(restored.read<dynamic>(entry.key), entry.value);
      }
      expect(restored.read<Map>('settings')!['rounds'], 3);
      expect(restored.read<List>('sessions'), hasLength(1));
      expect(restored.read<int>('safetyAcknowledgementVersion'), 1);
      expect(restored.read<String>('activatedInviteCode'), 'chuotbu');
      await restored.remove('activeSession');
      expect(StorageService(preferences).read<Map>('activeSession'), isNull);
      expect(restored.read<String>('missing'), isNull);
    },
  );

  test('Write awaits the platform result and propagates failures', () async {
    final preferences = TestPreferences();
    final storage = StorageService(preferences);
    preferences.control.pendingWrite = Completer<void>();
    var completed = false;
    final write = storage
        .write('settings', {'rounds': 5})
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, false);
    preferences.control.pendingWrite!.complete();
    await write;
    expect(completed, true);
    preferences.control.failure = StateError('platform write failed');
    await expectLater(
      storage.write('settings', {'rounds': 8}),
      throwsStateError,
    );
  });
}
