import 'package:shared_preferences/shared_preferences.dart';

/// Persists the device session token without macOS Keychain (avoids signing entitlements).
class TokenStorage {
  static const _tokenKey = 'ventos_access_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
