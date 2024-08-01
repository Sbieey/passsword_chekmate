// package com.example.app;

// import android.accounts.Account;
// import android.accounts.AccountManager;
// import io.flutter.embedding.android.FlutterActivity;
// import io.flutter.plugin.common.MethodCall;
// import io.flutter.plugin.common.MethodChannel;
// import androidx.annotation.NonNull;
// import java.util.ArrayList;
// import java.util.List;

// public class MainActivity extends FlutterActivity {
//     private static final String CHANNEL = "com.example.app/account_manager";

//     @Override
//     public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
//         super.configureFlutterEngine(flutterEngine);

//         new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
//             .setMethodCallHandler(
//                 (call, result) -> {
//                     if (call.method.equals("getAccounts")) {
//                         AccountManager accountManager = AccountManager.get(this);
//                         Account[] accounts = accountManager.getAccounts();
//                         List<String> accountNames = new ArrayList<>();
//                         for (Account account : accounts) {
//                             accountNames.add(account.name);
//                         }
//                         result.success(accountNames);
//                     } else {
//                         result.notImplemented();
//                     }
//                 }
//             );
//     }
// }

package com.example.password_manager;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.password_manager/account";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("storePassword")) {
                                String app = call.argument("app");
                                String password = call.argument("password");
                                storePassword(app, password);
                                result.success(null);
                            } else if (call.method.equals("getPassword")) {
                                String app = call.argument("app");
                                String password = getPassword(app);
                                result.success(password);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void storePassword(String app, String password) {
        AccountManager accountManager = AccountManager.get(this);
        Account account = new Account(app, "com.example.password_manager");
        accountManager.addAccountExplicitly(account, password, null);
    }

    private String getPassword(String app) {
        AccountManager accountManager = AccountManager.get(this);
        Account[] accounts = accountManager.getAccountsByType("com.example.password_manager");

        for (Account account : accounts) {
            if (account.name.equals(app)) {
                return accountManager.getPassword(account);
            }
        }
        return null;
    }
}
