import 'dart:convert';
import 'platform_io.dart' as platform;

class SessionStore {
  Future<Map<String, dynamic>?> read() async {
    final raw = await platform.readSetting('session');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(String base, String token, String expires) =>
      platform.writeSetting(
        'session',
        jsonEncode({'base': base, 'token': token, 'expires': expires}),
      );
  Future<void> clear() => platform.deleteSetting('session');
}
