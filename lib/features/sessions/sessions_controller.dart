import 'package:get/get.dart';

import '../../data/repositories/session_repository.dart';

class SessionsController extends GetxController {
  final SessionRepository repository;
  SessionsController(this.repository);
}
