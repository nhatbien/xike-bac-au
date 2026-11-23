import 'dart:async';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // The app signals over a localhost socket from the integration test before
  // measuring playback across a real switch to iOS Settings and back.
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 39551);
  final subscription = server.listen((socket) async {
    socket.listen((data) async {
      if (!String.fromCharCodes(data).contains('background')) return;
      final background = await Process.run('xcrun', [
        'simctl',
        'launch',
        'booted',
        'com.apple.Preferences',
      ]);
      await Future<void>.delayed(const Duration(seconds: 5));
      final foreground = await Process.run('xcrun', [
        'simctl',
        'launch',
        'booted',
        'vn.xike.xikeBacAu',
      ]);
      await Directory('artifacts/ios').create(recursive: true);
      await File('artifacts/ios/background-check.txt').writeAsString(
        'Settings launch: ${background.exitCode}\n${background.stdout}\n'
        'App resume: ${foreground.exitCode}\n${foreground.stdout}\n',
      );
      socket.write('returned');
      await socket.flush();
      await socket.close();
    });
  });
  try {
    await integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        await Directory('artifacts/ios/screenshots').create(recursive: true);
        await File('artifacts/ios/screenshots/$name.png').writeAsBytes(bytes);
        return true;
      },
    );
  } finally {
    await subscription.cancel();
    await server.close();
  }
}
