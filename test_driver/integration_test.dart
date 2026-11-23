import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const adb = '/Users/quocthanhvu/Library/Android/sdk/platform-tools/adb';
Future<void> main() async {
  await Process.run(adb, [
    'shell',
    'pm',
    'grant',
    'vn.xike.xike_bac_au',
    'android.permission.POST_NOTIFICATIONS',
  ]);
  await Process.run(adb, ['logcat', '-c']);
  final logcat = await Process.start(adb, [
    'logcat',
    '-v',
    'brief',
    '-s',
    'flutter',
  ]);
  var checked = false;
  final subscription = logcat.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
        if (!checked && line.contains('QA_SCREEN_LOCK')) {
          checked = true;
          await Process.run(adb, [
            'shell',
            'input',
            'keyevent',
            'KEYCODE_SLEEP',
          ]);
          await Future<void>.delayed(const Duration(seconds: 5));
          final services = await Process.run(adb, [
            'shell',
            'dumpsys',
            'activity',
            'services',
            'vn.xike.xike_bac_au',
          ]);
          final media = await Process.run(adb, [
            'shell',
            'dumpsys',
            'media_session',
          ]);
          await Directory('artifacts').create(recursive: true);
          await File('artifacts/background-check.txt').writeAsString(
            'Services while screen off:\n${services.stdout}\nMedia:\n${media.stdout}',
          );
          await Process.run(adb, [
            'shell',
            'input',
            'keyevent',
            'KEYCODE_WAKEUP',
          ]);
          await Process.run(adb, ['shell', 'wm', 'dismiss-keyguard']);
        }
      });
  try {
    await integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        await Directory('artifacts/screenshots').create(recursive: true);
        await File('artifacts/screenshots/$name.png').writeAsBytes(bytes);
        return true;
      },
    );
  } finally {
    await subscription.cancel();
    logcat.kill();
  }
}
