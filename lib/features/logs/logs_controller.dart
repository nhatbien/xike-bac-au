import 'dart:io';

import 'package:flutter/rendering.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';

import '../../core/services/logging_service.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../breathing/breathing_controller.dart';

class LogsController extends GetxController {
  final LoggingService logs;
  LogsController(this.logs);
  final info = 'Đang đọc thông tin thiết bị…'.obs;
  @override
  void onInit() {
    super.onInit();
    refreshInfo();
  }

  Future<void> refreshInfo() async {
    try {
      final package = await PackageInfo.fromPlatform();
      final device = Platform.isAndroid
          ? await DeviceInfoPlugin().androidInfo
          : null;
      final appleDevice = Platform.isIOS
          ? await DeviceInfoPlugin().iosInfo
          : null;
      final permission = Platform.isAndroid
          ? (await Permission.notification.status).name
          : 'không yêu cầu trên iOS (Now Playing)';
      final platformDescription = device != null
          ? 'Android ${device.version.release} (API ${device.version.sdkInt})'
          : appleDevice != null
          ? '${appleDevice.systemName} ${appleDevice.systemVersion}'
          : Platform.operatingSystemVersion;
      final hardware = device != null
          ? '${device.manufacturer} ${device.model}'
          : appleDevice?.utsname.machine ?? Platform.operatingSystem;
      final b = Get.find<BreathingController>();
      final repository = Get.find<SessionRepository>();
      final settings = Get.find<SettingsRepository>().settings.value;
      final directories = [
        await getApplicationDocumentsDirectory(),
        await getTemporaryDirectory(),
      ];
      var bytes = 0;
      for (final dir in directories) {
        await for (final f in dir.list(recursive: true, followLinks: false)) {
          if (f is File) {
            try {
              bytes += await f.length();
            } catch (_) {}
          }
        }
      }
      info.value =
          '${package.appName} ${package.version}+${package.buildNumber}\n$platformDescription\n$hardware\nÂm thanh: PCM 22050Hz mono 16-bit\nLịch gốc: ${b.manifest.phrases.length} câu, ${b.manifest.phrases.values.fold(0, (n, p) => n + p.cues.length)} đoạn giọng\nSố nhịp mỗi hiệp: 40\nPreload: ${b.loading.value
              ? 'đang nạp'
              : b.audio.ready
              ? 'sẵn sàng'
              : 'chưa nạp'}\nPlayer: ${b.audio.player.processingState.name}, playing=${b.audio.player.playing}\nSố buổi: ${repository.sessions.length}\nNín thở vui: ${repository.attempts.length} lần\nCài đặt: ${settings.rounds} hiệp · nín ${settings.holdSeconds}s · giữ ${settings.recoverySeconds}s\nThông báo: $permission\nBuổi đang chạy: ${b.active.value}, tạm dừng: ${b.paused.value}\nDung lượng dữ liệu + cache: ${(bytes / 1048576).toStringAsFixed(2)} MiB';
    } catch (e) {
      info.value = 'Không đọc được một phần thông tin thiết bị: $e';
      logs.log('Thông tin thiết bị: $e');
    }
  }

  String get text =>
      '${info.value}\n\nNhật ký gần nhất (tối đa 300):\n${logs.entries.reversed.join('\n')}';
  Future<void> share({Rect? origin}) async {
    await refreshInfo();
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Nhật ký Ìe Bắc Âu',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      logs.log('Lỗi mở bảng chia sẻ: $e');
      Get.snackbar(
        'Chia sẻ',
        'Không mở được bảng chia sẻ. Có thể chọn và sao chép nhật ký.',
      );
    }
  }
}
