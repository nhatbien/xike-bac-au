import '../../config/invite_codes.dart';
import '../../core/services/storage_service.dart';

class InviteAccess {
  static const storageKey = 'activatedInviteCode';

  static String normalize(String code) => code.trim().toLowerCase();

  static bool isValid(String code) => inviteCodes.contains(normalize(code));

  static bool isActivated(StorageService storage) {
    final saved = storage.read<String>(storageKey);
    return saved != null && isValid(saved);
  }

  static Future<bool> activate(StorageService storage, String code) async {
    if (!isValid(code)) return false;
    try {
      await storage.write(storageKey, normalize(code));
      return true;
    } catch (_) {
      // The preferences cache can update before the platform write fails.
      try {
        await storage.remove(storageKey);
      } catch (_) {}
      rethrow;
    }
  }
}
