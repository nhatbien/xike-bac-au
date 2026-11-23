import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/services/storage_service.dart';
import '../legal/legal_content.dart';

class SafetyAcknowledgement {
  static const version = 1;
  static const key = 'safetyAcknowledgementVersion';
  static bool get accepted =>
      Get.find<StorageService>().read<int>(key) == version;
}

/// Protect named training routes as well as navigation from the home screen.
class SafetyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) => SafetyAcknowledgement.accepted
      ? null
      : RouteSettings(
          name: '/safety?next=${Uri.encodeComponent(route ?? '/')}',
        );
}

class SafetyView extends StatefulWidget {
  final String? nextRoute;
  const SafetyView({super.key, this.nextRoute});

  @override
  State<SafetyView> createState() => _SafetyViewState();
}

class _SafetyViewState extends State<SafetyView> {
  bool checked = false;
  bool saving = false;
  String? error;

  void _leave() {
    if (widget.nextRoute == null) {
      Get.back();
    } else {
      Get.offNamed('/');
    }
  }

  Future<void> _accept() async {
    if (!checked || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await Get.find<StorageService>().write(
        SafetyAcknowledgement.key,
        SafetyAcknowledgement.version,
      );
      if (!mounted) return;
      final target = widget.nextRoute;
      if (target == null) {
        Get.back();
      } else {
        Get.offNamed(
          target == '/breathing' || target == '/hold' ? target : '/',
        );
      }
    } catch (_) {
      // The preferences cache can update before the platform write fails.
      // Roll it back if persistence failed so training stays gated.
      try {
        await Get.find<StorageService>().remove(SafetyAcknowledgement.key);
      } catch (_) {}
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Không lưu được xác nhận. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.nextRoute == null && !saving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !saving) _leave();
    },
    child: Scaffold(
      body: AppBackground(
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Tập thở an toàn', style: serif(28)),
                    ),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: LegalContent.data,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Không đọc được cảnh báo. Vui lòng mở lại ứng dụng.',
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              for (final section in snapshot.data!['safety'])
                                DashedBorderCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        section['title'] as String,
                                        style: serif(20),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (section['paragraphs'] as List).join(
                                          '\n\n',
                                        ),
                                        style: body(16),
                                      ),
                                    ],
                                  ),
                                ),
                              CheckboxListTile(
                                key: const ValueKey('safety-check'),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: checked,
                                onChanged: saving
                                    ? null
                                    : (value) => setState(
                                        () => checked = value ?? false,
                                      ),
                                title: const Text(
                                  'Tôi đã đọc cảnh báo và hiểu rằng có thể dừng tập bất cứ lúc nào.',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          error!,
                          style: body(14, color: AppColors.coral),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            key: const ValueKey('safety-continue'),
                            onPressed: checked && !saving ? _accept : null,
                            child: Text(
                              saving ? 'Đang lưu…' : 'Đã hiểu, tiếp tục',
                            ),
                          ),
                          TextButton(
                            onPressed: saving ? null : _leave,
                            child: Text(
                              widget.nextRoute == null
                                  ? 'Quay lại'
                                  : 'Để sau, về trang chủ',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
