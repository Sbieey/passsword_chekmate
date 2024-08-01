import 'package:flutter/services.dart';

class AccountManagerHelper {
  static const platform = MethodChannel('com.example.app/account_manager');

  Future<List<String>> getAccounts() async {
    try {
      final List<String> accounts = await platform.invokeMethod('getAccounts');
      return accounts;
    } on PlatformException catch (e) {
      print("Failed to get accounts: '${e.message}'.");
      return [];
    }
  }
}
