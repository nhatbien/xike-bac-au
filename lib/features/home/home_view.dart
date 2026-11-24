import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/utils/duration_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/repositories/statistics_repository.dart';
import '../breathing/breathing_controller.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) => Obx(() {
    final settings = controller.settings.settings.value;
    final calc = Get.find<DurationCalculator>();
    final stats = StatisticsRepository(controller.sessions.sessions);
    final record = controller.sessions.attempts.fold(
      0,
      (v, a) => v > a.durationMilliseconds ? v : a.durationMilliseconds,
    );
    final menu = [
      (
        '/hold',
        'Nín thở vui',
        'theo dõi thời gian · dừng khi cần thở${record > 0 ? ' · kỷ lục ${stopwatchText(record)}' : ''}',
        'timer',
        AppColors.pink,
        AppColors.coral,
      ),
      (
        '/settings',
        'Cài đặt',
        'số hiệp, giây nín thở, giây giữ hơi phục hồi',
        'settings',
        AppColors.yellow,
        const Color(0xFFB97A12),
      ),
      (
        '/statistics',
        'Thống kê',
        'lịch tập, kỷ lục, huy hiệu',
        'stats',
        AppColors.green,
        AppColors.teal,
      ),
      (
        '/sessions',
        'Các buổi đã tập',
        controller.sessions.sessions.isEmpty
            ? 'chưa có buổi nào'
            : '${controller.sessions.sessions.length} buổi đã tập',
        'sessions',
        AppColors.lightBlue,
        AppColors.blue,
      ),
      (
        '/logs',
        'Nhật ký',
        'chụp màn này gửi lại khi có lỗi',
        'logs',
        AppColors.paperDark,
        AppColors.muted,
      ),
    ];
    return AppPage(
      children: [
        const SizedBox(height: 10),
        Text(
          'Xì ke bắc âu',
          style: serif(36).copyWith(height: 1.15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'thở cùng ông Wim · rảnh tay từ đầu tới cuối',
          style: body(15, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 7),
        DashedBorderCard(
          color: AppColors.green,
          borderColor: AppColors.mint,
          child: Row(
            children: [
              const AppIcon('snow', color: AppColors.teal, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stats.sessions.isEmpty
                      ? 'Chưa có buổi nào. Buổi đầu tiên chỉ mất chừng mười lăm phút.'
                      : 'Đã tập ${stats.sessions.length} buổi · chuỗi ${stats.currentStreak(DateTime.now())} ngày. Tập vừa sức và dừng khi cần.',
                  style: body(16),
                ),
              ),
            ],
          ),
        ),
        PrimaryActionCard(
          title: Get.find<BreathingController>().active.value
              ? 'Tiếp tục thở'
              : 'Bắt đầu thở',
          subtitle:
              '${calc.summary(settings)} · khoảng ${calc.minutes(settings)} phút',
          onTap: () => Get.toNamed('/breathing'),
        ),
        const SizedBox(height: 8),
        ...menu.map(
          (m) => DashedBorderCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => Get.toNamed(m.$1),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.$5,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(m.$4, color: m.$6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.$2, style: serif(18.5).copyWith(height: 1.5)),
                      Text(
                        m.$3,
                        style: body(
                          13.5,
                          color: AppColors.muted,
                        ).copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('›', style: serif(30, color: AppColors.border)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            'Thở lại bình thường bất cứ khi nào cần. Không cố theo hết thời gian của app.',
            style: serif(
              16.5,
              weight: FontWeight.w400,
              color: AppColors.muted,
              italic: true,
            ).copyWith(height: 1.55),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => Get.to(() => const AboutView()),
          child: Text(
            'Xì ke bắc âu 1.0.0 · thở theo cách của Wim Hof, không phải app chính thức của ông',
            style: body(12, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  });
}

class AboutView extends StatelessWidget {
  const AboutView({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Giới thiệu',
    children: [
      DashedBorderCard(child: Image.asset('assets/web/dau.jpg')),
      const SizedBox(height: 16),
      Text(
        'Xì ke bắc âu do MAX cung cấp để hướng dẫn tập thở bằng âm thanh và theo dõi lịch sử trên thiết bị. Đây là ứng dụng độc lập, không phải ứng dụng chính thức của Wim Hof và không tuyên bố được ông bảo trợ.',
        style: serif(25, weight: FontWeight.w500).copyWith(height: 1.34),
      ),
    ],
  );
}
