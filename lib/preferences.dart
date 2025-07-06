// lib/utils/preferences.dart
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const _hostKey = 'smb_host';
  static const _userKey = 'smb_user';
  static const _passKey = 'smb_pass';

  static Future<void> save(String host, String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
    await prefs.setString(_userKey, user);
    await prefs.setString(_passKey, pass);
  }

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'host': prefs.getString(_hostKey) ?? '',
      'user': prefs.getString(_userKey) ?? '',
      'pass': prefs.getString(_passKey) ?? '',
    };
  }
}
