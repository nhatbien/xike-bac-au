import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/utils/duration_calculator.dart';
import '../../core/utils/time_formatter.dart';
import 'settings_controller.dart';
import 'backup_settings_card.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) => Obx(() {
    final s = controller.value;
    final calc = Get.find<DurationCalculator>();
    return AppPage(
      title: 'Cài đặt buổi thở',
      children: [
        DashedBorderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionTitle('Số hiệp'),
              GridView.count(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 46,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  10,
                  (i) => OutlinedButton(
                    key: ValueKey('round-${i + 1}'),
                    onPressed: () => controller.rounds(i + 1),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: s.rounds == i + 1
                          ? AppColors.coral
                          : const Color(0xFFFFFDF7),
                      foregroundColor: s.rounds == i + 1
                          ? Colors.white
                          : AppColors.ink,
                      side: BorderSide(
                        color: s.rounds == i + 1
                            ? const Color(0xFFC8634A)
                            : AppColors.border,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SettingSliderCard(
          title: 'Nín thở mỗi hiệp',
          value: s.holdSeconds,
          min: 15,
          max: 600,
          divisions: 20,
          steps: const [
            15,
            30,
            45,
            60,
            75,
            90,
            105,
            120,
            135,
            150,
            165,
            180,
            210,
            240,
            270,
            300,
            360,
            420,
            480,
            540,
            600,
          ],
          hint: 'thở ra hết rồi nín',
          maximum: '10 phút',
          onChanged: controller.hold,
          sliderKey: 'hold-slider',
        ),
        SettingSliderCard(
          title: 'Hít vào giữ (phục hồi)',
          value: s.recoverySeconds,
          min: 5,
          max: 60,
          divisions: 10,
          steps: const [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60],
          hint: 'hít đầy rồi giữ',
          maximum: '60 giây',
          onChanged: controller.recovery,
          sliderKey: 'recovery-slider',
        ),
        DashedBorderCard(
          color: AppColors.yellow,
          borderColor: AppColors.mustard,
          child: Text(
            '${calc.summary(s)}\n${calc.estimate(s)}',
            style: body(16, weight: FontWeight.w600),
          ),
        ),
        DashedBorderCard(
          child: Text(
            'Mỗi hiệp: thở 40 nhịp sâu theo giọng ông Wim (mỗi nhịp 3,26 giây: hít 1,7, thở 1,56, đúng nhịp clip mẫu) → thở ra hết rồi NÍN theo số giây trên → hít đầy và GIỮ hơi phục hồi → thả ra, sang hiệp mới.\nBấm Bắt đầu là app tự dẫn tới hết, không cần chạm gì.\nThời gian chỉ là cài đặt bài tập, không phải mục tiêu bắt buộc. Thở lại bình thường và dừng ngay khi cần; không cố nín theo đồng hồ.\nĐừng tập khi đang lái xe, đang ở dưới nước hay đang đứng: ngồi hoặc nằm chỗ an toàn.',
            style: body(14.5, color: AppColors.muted),
          ),
        ),
        const BackupSettingsCard(),
        DashedBorderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionTitle('Thông tin & hỗ trợ'),
              for (final link in const [
                ('/privacy', 'Chính sách quyền riêng tư'),
                ('/terms', 'Điều khoản sử dụng'),
                ('/support', 'Hỗ trợ'),
                ('/safety', 'Xem lại cảnh báo an toàn'),
                ('/licenses', 'Giấy phép nguồn mở'),
              ])
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(link.$2, style: body(16)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(link.$1),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  });
}

class SettingSliderCard extends StatelessWidget {
  final String title, hint, maximum, sliderKey;
  final int value;
  final double min, max;
  final int divisions;
  final List<int>? steps;
  final ValueChanged<double> onChanged;
  const SettingSliderCard({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.steps,
    required this.hint,
    required this.maximum,
    required this.onChanged,
    required this.sliderKey,
  });
  int _nearestIndex() {
    var best = 0;
    for (var i = 1; i < steps!.length; i++) {
      if ((steps![i] - value).abs() < (steps![best] - value).abs()) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) => DashedBorderCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 6),
          child: Text(
            durationLabel(value),
            style: serif(30, weight: FontWeight.w700).copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [AppColors.green, AppColors.yellow],
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                  thumbShape: const _PaperSliderThumb(),
                ),
                child: Slider(
                  padding: EdgeInsets.zero,
                  key: ValueKey(sliderKey),
                  value: steps == null
                      ? value.toDouble()
                      : _nearestIndex().toDouble(),
                  min: steps == null ? min : 0,
                  max: steps == null ? max : (steps!.length - 1).toDouble(),
                  divisions: divisions,
                  onChanged: (n) => onChanged(
                    steps == null ? n : steps![n.round()].toDouble(),
                  ),
                  semanticFormatterCallback: (n) => durationLabel(
                    steps == null ? n.round() : steps![n.round()],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toInt()} giây',
              style: body(13, color: AppColors.muted),
            ),
            Flexible(
              child: Text(
                hint,
                style: body(13, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
            Text(maximum, style: body(13, color: AppColors.muted)),
          ],
        ),
      ],
    ),
  );
}

class _PaperSliderThumb extends SliderComponentShape {
  const _PaperSliderThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(30, 30);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: 15));
    canvas.drawShadow(path, const Color(0x66783C1E), 3, true);
    canvas.drawCircle(center, 15, Paint()..color = const Color(0xFFFFFDF7));
    canvas.drawCircle(center, 12, Paint()..color = AppColors.coral);
  }
}
