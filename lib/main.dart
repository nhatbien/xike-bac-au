import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'core/services/logging_service.dart';
import 'core/services/storage_service.dart';
import 'features/invite/invite_gate.dart';
import 'features/safety/safety_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Lora', 'BeVietnamPro']) {
      final license = await rootBundle.loadString(
        'assets/web/fonts/OFL-$font.txt',
      );
      yield LicenseEntryWithLineBreaks([font], license);
    }
  });
  await initializeDependencies();
  PlatformDispatcher.instance.onError = (error, stack) {
    Get.find<LoggingService>().log('Runtime: $error\n$stack');
    return false;
  };
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const XikeApp());
}

class XikeApp extends StatelessWidget {
  const XikeApp({super.key});
  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Xì ke bắc âu',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    themeMode: ThemeMode.light,
    initialRoute: SafetyAcknowledgement.accepted ? '/' : '/safety?next=%2F',
    getPages: AppPages.pages,
    defaultTransition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 220),
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarDividerColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.5),
        ),
        child: InviteGate(storage: Get.find<StorageService>(), child: child!),
      ),
    ),
  );
}
