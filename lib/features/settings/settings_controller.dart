import 'package:get/get.dart';

import '../../data/models/breathing_settings.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsController extends GetxController {
  final SettingsRepository repository;
  SettingsController(this.repository);
  BreathingSettings get value => repository.settings.value;
  void voice(GuidanceVoice voice) =>
      repository.save(value.copyWith(voice: voice));
  void rounds(int n) => repository.save(value.copyWith(rounds: n));
  void hold(double n) =>
      repository.save(value.copyWith(holdSeconds: n.round()));
  void recovery(double n) =>
      repository.save(value.copyWith(recoverySeconds: n.round()));
}
