import 'package:get/get.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/session_repository.dart';

class HomeController extends GetxController {
  final SettingsRepository settings;
  final SessionRepository sessions;
  HomeController(this.settings, this.sessions);
}
