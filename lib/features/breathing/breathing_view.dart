import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/services/breathing_engine.dart';
import '../../core/utils/duration_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../sessions/session_detail_view.dart';
import 'breathing_controller.dart';

class BreathingView extends StatefulWidget {
  const BreathingView({super.key});
  @override
  State<BreathingView> createState() => _BreathingViewState();
}

class _BreathingViewState extends State<BreathingView> {
  final c = Get.find<BreathingController>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!c.active.value) c.start();
      for (var i = 0; i < 24; i++) {
        precacheImage(
          ResizeImage(
            AssetImage('assets/web/khung/k${i.toString().padLeft(2, '0')}.jpg'),
            width: 864,
          ),
          context,
        );
      }
    });
  }

  Future<void> _stop() async {
    if (await confirmAction(
      'Dừng buổi thở?',
      'Buổi dừng giữa chừng không được ghi thành hoàn thành.',
      action: 'Dừng',
    )) {
      await c.stop();
      if (mounted) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    if (c.result.value != null) {
      return SessionDetailView(session: c.result.value!, completed: true);
    }
    if (c.error.isNotEmpty) {
      return AppPage(
        title: 'Buổi thở',
        children: [
          EmptyStateCard(c.error.value),
          RoundedOutlineButton('Thử lại', onPressed: c.start),
        ],
      );
    }
    final s = c.snapshot.value;
    final engine = c.engine;
    return PopScope(
      canPop: !c.active.value && !c.loading.value,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _stop();
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = min(640.0, constraints.maxWidth);
                final imageHeight = min(
                  width * 1.25,
                  constraints.maxHeight * .58,
                );
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              SizedBox(
                                width: width,
                                height: imageHeight,
                                child: _BreathingFrames(lungs: s?.lungs ?? .3),
                              ),
                              Positioned(
                                top: 10,
                                left: 12,
                                right: 12,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _chip(
                                      'Hiệp ${s?.stage.round ?? 1} / ${engine?.settings.rounds ?? 3}',
                                    ),
                                    Flexible(
                                      child: _chip(
                                        '${_phaseName(s?.stage.phase)} · ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Transform.translate(
                            offset: const Offset(0, -26),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: DashedBorderCard(
                                radius: 22,
                                margin: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 96,
                                      child: Center(
                                        child: Text(
                                          c.loading.value
                                              ? 'Chuẩn bị…'
                                              : s?.title ?? 'Ngồi thoải mái',
                                          style: serif(
                                            (s?.title.length ?? 10) > 5
                                                ? 38
                                                : 76,
                                            weight: FontWeight.w700,
                                            color: _color(s),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.loading.value
                                          ? 'đang mở tiếng…'
                                          : _subtitle(s),
                                      style: body(15.5, color: AppColors.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (c.loading.value)
                                      const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: LinearProgressIndicator(
                                          color: AppColors.mint,
                                        ),
                                      ),
                                    BreathingProgressBar(s?.lungs ?? .3),
                                    BreathingProgressBar(
                                      s?.progress ?? 0,
                                      total: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${((s?.progress ?? 0) * 100).floor()}% buổi',
                                          style: body(
                                            12.5,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        Text(
                                          'còn ${clock(s?.remainingSeconds ?? 0)}',
                                          style: body(
                                            12.5,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RoundedOutlineButton(
                                            c.paused.value
                                                ? 'Tiếp tục'
                                                : 'Tạm dừng',
                                            onPressed: c.loading.value
                                                ? null
                                                : c.togglePause,
                                            primary: c.paused.value,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: RoundedOutlineButton(
                                            'Dừng',
                                            onPressed: c.loading.value
                                                ? null
                                                : _stop,
                                            danger: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Phím âm lượng bên hông máy: to / nhỏ tiếng · tắt màn hình vẫn thở tiếp',
                                      style: body(12.5, color: AppColors.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  });
  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.paper.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
    child: Text(
      text,
      style: body(14, weight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    ),
  );
  String _phaseName(BreathingPhase? p) => switch (p) {
    BreathingPhase.guidedBreathing => 'Thở sâu',
    BreathingPhase.exhaleAndHold => 'Nín thở',
    BreathingPhase.recoveryHold => 'Giữ hơi',
    BreathingPhase.nextRound => 'Hiệp mới',
    BreathingPhase.completed => 'Hoàn thành',
    _ => 'Chuẩn bị',
  };
  Color _color(BreathingSnapshot? s) => switch (s?.stage.phase) {
    BreathingPhase.guidedBreathing =>
      s?.title == 'IN' ? AppColors.coral : AppColors.blue,
    BreathingPhase.exhaleAndHold => AppColors.teal,
    BreathingPhase.recoveryHold => const Color(0xFFB97A12),
    _ => AppColors.ink,
  };
  String _subtitle(BreathingSnapshot? s) {
    if (s == null) return '';
    return switch (s.stage.phase) {
      BreathingPhase.preparing =>
        'thả lỏng vai · ${Get.find<DurationCalculator>().summary(c.engine!.settings)}',
      BreathingPhase.guidedBreathing =>
        'nhịp ${s.breath} / 40 · hít đầy, thở ra nhẹ nhàng',
      BreathingPhase.exhaleAndHold => 'thở ra hết rồi nín · thả lỏng vai',
      BreathingPhase.recoveryHold => 'hít đầy rồi giữ',
      BreathingPhase.nextRound => 'thả lỏng · trở lại nhịp thở',
      BreathingPhase.completed => 'thở bình thường · thư giãn thêm một chút',
    };
  }
}

class _BreathingFrames extends StatelessWidget {
  final double lungs;
  const _BreathingFrames({required this.lungs});
  @override
  Widget build(BuildContext context) {
    final f = lungs * 23;
    final i = f.floor().clamp(0, 23);
    Widget frame(int n) => Image(
      image: ResizeImage(
        AssetImage('assets/web/khung/k${n.toString().padLeft(2, '0')}.jpg'),
        width: 864,
      ),
      fit: BoxFit.cover,
      alignment: const Alignment(0, .2),
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        frame(i),
        if (i < 23) Opacity(opacity: f - i, child: frame(i + 1)),
      ],
    );
  }
}
