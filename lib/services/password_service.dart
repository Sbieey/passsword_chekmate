import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class PasswordService {
  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');

  String _encryptPassword(String password, encrypt.IV iv) {
    final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(password, iv: iv);
    print('Encrypted password for $password: ${encrypted.base64}');
    return '${iv.base64}:${encrypted.base64}';
  }

  String _decryptPassword(String encryptedData) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      print('Error: Encrypted data is not in the expected format.');
      return '';
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedPassword = parts[1];
    final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

    try {
      final decrypted = encrypter.decrypt64(encryptedPassword, iv: iv);
      print('Decrypted password: $decrypted');
      return decrypted;
    } catch (e) {
      print('Error decrypting password: $e');
      return '';
    }
  }

  Future<void> savePassword(String appName, String password) async {
    final iv = encrypt.IV.fromLength(16);
    final encryptedPassword = _encryptPassword(password, iv);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(appName, encryptedPassword);
    print('Saved encrypted password for $appName: $encryptedPassword');
  }

  Future<Map<String, String>> getPasswords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final passwords = <String, String>{};
    for (var key in keys) {
      final encryptedPassword = prefs.getString(key) ?? '';
      passwords[key] = _decryptPassword(encryptedPassword);
    }
    print('Retrieved passwords: $passwords');
    return passwords;
  }

  Future<void> updatePassword(String appName, String newPassword) async {
    final iv = encrypt.IV.fromLength(16);
    final encryptedPassword = _encryptPassword(newPassword, iv);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(appName, encryptedPassword);
    print('Updated encrypted password for $appName: $encryptedPassword');
  }

  Future<void> deletePassword(String appName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(appName);
  }

  Future<bool> isPasswordReused(String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      final decryptedPassword = _decryptPassword(prefs.getString(key) ?? '');
      if (decryptedPassword == password) {
        return true;
      }
    }
    return false;
  }

  Future<void> clearPasswords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('Cleared all stored passwords.');
  }
}
