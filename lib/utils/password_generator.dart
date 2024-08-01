import 'dart:math';

class PasswordGenerator {
  static const _upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lowerCase = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _specialChars = '!@#\$&*~';

  static String generate() {
    const length = 12;
    final random = Random.secure();
    
    String password = '';
    
    while (!_isValidPassword(password)) {
      password = List.generate(length, (index) {
        int charType = random.nextInt(4);
        switch (charType) {
          case 0:
            return _upperCase[random.nextInt(_upperCase.length)];
          case 1:
            return _lowerCase[random.nextInt(_lowerCase.length)];
          case 2:
            return _digits[random.nextInt(_digits.length)];
          case 3:
            return _specialChars[random.nextInt(_specialChars.length)];
          default:
            return '';
        }
      }).join();
    }

    return password;
  }

  static bool _isValidPassword(String password) {
    if (password.length < 8) {
      return false;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return false;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return false;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return false;
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return false;
    }
    return true;
  }
}
