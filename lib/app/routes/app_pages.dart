import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/home/home_view.dart';
import '../../features/home/home_controller.dart';
import '../../features/settings/settings_view.dart';
import '../../features/settings/settings_controller.dart';
import '../../features/breathing/breathing_view.dart';
import '../../features/breath_hold/breath_hold_view.dart';
import '../../features/breath_hold/breath_hold_controller.dart';
import '../../features/statistics/statistics_view.dart';
import '../../features/statistics/statistics_controller.dart';
import '../../features/sessions/sessions_view.dart';
import '../../features/sessions/sessions_controller.dart';
import '../../features/logs/logs_view.dart';
import '../../features/logs/logs_controller.dart';

import '../../features/legal/legal_view.dart';
import '../../features/safety/safety_view.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: '/licenses',
      page: () => const LicensePage(applicationName: 'Xì ke bắc âu'),
    ),
    GetPage(name: '/privacy', page: () => const LegalView('privacy')),
    GetPage(name: '/terms', page: () => const LegalView('terms')),
    GetPage(name: '/support', page: () => const LegalView('support')),
    GetPage(
      name: '/safety',
      page: () => SafetyView(nextRoute: Get.parameters['next']),
    ),
    GetPage(
      name: '/',
      page: () => const HomeView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => HomeController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: '/settings',
      page: () => const SettingsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => SettingsController(Get.find())),
      ),
    ),
    GetPage(
      name: '/breathing',
      page: () => const BreathingView(),
      middlewares: [SafetyMiddleware()],
    ),
    GetPage(
      name: '/hold',
      middlewares: [SafetyMiddleware()],
      page: () => const BreathHoldView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => BreathHoldController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: '/statistics',
      page: () => const StatisticsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => StatisticsController(Get.find())),
      ),
    ),
    GetPage(
      name: '/sessions',
      page: () => const SessionsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => SessionsController(Get.find())),
      ),
    ),
    GetPage(
      name: '/logs',
      page: () => const LogsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => LogsController(Get.find())),
      ),
    ),
  ];
}
