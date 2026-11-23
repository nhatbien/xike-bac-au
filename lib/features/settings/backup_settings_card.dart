import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/services/backup_service.dart';
import '../../data/models/training_backup.dart';
import '../breath_hold/breath_hold_controller.dart';
import '../breathing/breathing_controller.dart';

class BackupSettingsCard extends StatefulWidget {
  const BackupSettingsCard({super.key});

  @override
  State<BackupSettingsCard> createState() => _BackupSettingsCardState();
}

class _BackupSettingsCardState extends State<BackupSettingsCard> {
  bool _busy = false;
  String? _message;
  bool _isError = false;

  void _setMessage(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isError = error;
    });
  }

  void _ensureIdle() {
    final breathing = Get.find<BreathingController>();
    final holding =
        Get.isRegistered<BreathHoldController>() &&
        Get.find<BreathHoldController>().running.value;
    if (breathing.active.value || breathing.loading.value || holding) {
      throw const FormatException(
        'Hãy kết thúc buổi tập hoặc lần nín thở đang chạy trước khi nhập dữ liệu.',
      );
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final backup = Get.find<BackupService>().snapshot();
      final contents = utf8.encode(backup.encode());
      if (contents.length > TrainingBackup.maxBytes) {
        throw const FormatException('Dữ liệu vượt giới hạn sao lưu 20 MB.');
      }
      final timestamp = backup.exportedAt
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final filename = 'xike-backup-$timestamp.json';
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Sao lưu Xì ke bắc âu',
          subject: 'Dữ liệu tập Xì ke bắc âu',
          files: [
            XFile.fromData(
              contents,
              mimeType: 'application/json',
              name: filename,
            ),
          ],
          fileNameOverrides: [filename],
          sharePositionOrigin: origin,
        ),
      );
      if (result.status == ShareResultStatus.success) {
        _setMessage('Đã chuyển file sao lưu tới nơi bạn chọn.');
      } else if (result.status == ShareResultStatus.unavailable) {
        _setMessage(
          'File đã được đưa vào bảng chia sẻ. Hãy lưu lại để dùng trên máy khác.',
        );
      }
    } on FormatException catch (error) {
      _setMessage(error.message, error: true);
    } catch (_) {
      _setMessage(
        'Không xuất được file sao lưu. Vui lòng thử lại.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      _ensureIdle();
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'File sao lưu JSON',
            extensions: ['json'],
            mimeTypes: ['application/json'],
            uniformTypeIdentifiers: ['public.json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > TrainingBackup.maxBytes) {
        throw const FormatException(
          'File quá lớn. Chỉ hỗ trợ file sao lưu tối đa 20 MB.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > TrainingBackup.maxBytes) {
        throw const FormatException(
          'File quá lớn. Chỉ hỗ trợ file sao lưu tối đa 20 MB.',
        );
      }
      final backup = TrainingBackup.decode(utf8.decode(bytes));
      if (!mounted) return;
      final service = Get.find<BackupService>();
      final current = service.snapshot();
      final date = backup.exportedAt.toLocal();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nhập dữ liệu sao lưu?'),
          content: SingleChildScrollView(
            child: Text(
              'File tạo ngày ${date.day}/${date.month}/${date.year}.\n'
              'Trong file: ${backup.sessions.length} buổi thở, ${backup.attempts.length} lần nín thở, ${backup.customBadges.length} huy hiệu tự thêm.\n\n'
              'Sẽ thay thế cài đặt, huy hiệu tự thêm và toàn bộ lịch sử hiện tại '
              '(${current.sessions.length} buổi thở, ${current.attempts.length} lần nín thở, ${current.customBadges.length} huy hiệu tự thêm). '
              'Hãy xuất dữ liệu hiện tại trước nếu bạn muốn giữ lại.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Thay thế và nhập'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _ensureIdle();
      // Keep the settings and navigation unavailable while replacing storage.
      final navigator = Navigator.of(context, rootNavigator: true);
      final progress = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text('Đang nhập dữ liệu…')),
              ],
            ),
          ),
        ),
      );
      try {
        await service.restore(backup);
      } finally {
        navigator.pop();
        await progress;
      }
      _setMessage(
        'Đã nhập ${backup.sessions.length} buổi thở và ${backup.attempts.length} lần nín thở, ${backup.customBadges.length} huy hiệu tự thêm. Cài đặt đã được khôi phục.',
      );
    } on FormatException catch (error) {
      _setMessage('Không nhập được dữ liệu. ${error.message}', error: true);
    } catch (_) {
      _setMessage(
        'Không nhập được file sao lưu. Kiểm tra file, dung lượng trống và thử lại.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DashedBorderCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionTitle('Sao lưu & chuyển dữ liệu'),
        Text(
          'Lưu cài đặt, buổi thở và các lần nín thở thành file để chuyển sang máy khác. Không cần tài khoản hoặc kết nối mạng.',
          style: body(15),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('export-backup'),
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('Xuất dữ liệu ra file'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('import-backup'),
          onPressed: _busy ? null : _import,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Nhập dữ liệu từ file'),
        ),
        const SizedBox(height: 8),
        Text(
          'Khi xuất, chọn Lưu vào Tệp, nơi lưu trên máy hoặc AirDrop. Trên máy mới, lưu file rồi chọn Nhập dữ liệu từ file. File không bao gồm mã mời, xác nhận an toàn hay buổi đang chạy.',
          style: body(13, color: AppColors.muted),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _message!,
              style: body(
                14,
                color: _isError ? AppColors.coral : AppColors.teal,
              ),
            ),
          ),
      ],
    ),
  );
}
