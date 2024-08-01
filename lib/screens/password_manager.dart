import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/password_service.dart';
import '../utils/password_generator.dart';
import 'password_list.dart';

class PasswordManager extends StatefulWidget {
  @override
  _PasswordManagerState createState() => _PasswordManagerState();
}

class _PasswordManagerState extends State<PasswordManager> {
  final PasswordService _passwordService = PasswordService();
  TextEditingController appNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bridge',
                style: TextStyle(
                  color: Color(0xFF224882),
                  fontSize: 20.0,
                ),
              ),
              TextSpan(
                text: 'Stacks',
                style: TextStyle(
                  color: Color(0xFFd1a104),
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
        ),
        // titleTextStyle: TextStyle(color: Color.fromARGB(255, 11, 45, 62)),
        // textColor: Color.fromARGB(255),
        actions: [
          IconButton(
            icon: Icon(Icons.password),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordList()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: appNameController,
                decoration: InputDecoration(
                  labelText: 'App/Account Name',
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String appName = appNameController.text;
                  String password = passwordController.text;

                  if (appName == '' || password == '') {
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => AlertDialog(
                    //     title: Text("Error"),
                    //     content:
                    //         Text("App/Account Name and Password are required."),
                    //     actions: <Widget>[
                    //       TextButton(
                    //         onPressed: () => Navigator.of(context).pop(),
                    //         child: Text("OK"),
                    //       ),
                    //     ],
                    //   ),
                    // );
                    showToast("Name and password are required");
                    return;
                  }

                  // Validate password
                  String? validationError = _validatePassword(password);
                  if (validationError != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Invalid Password"),
                        content: Text(validationError),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  bool isReused =
                      await _passwordService.isPasswordReused(password);
                  if (isReused) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Password Reuse Detected"),
                        content: Text(
                            "The entered password has been used before. Please generate a new password or change it."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                  } else {
                    await _passwordService.savePassword(appName, password);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Password Saved"),
                        content:
                            Text("The password has been saved for $appName."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Set New Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String newPassword = PasswordGenerator.generate();
                  passwordController.text = newPassword;
                },
                child: Text('Generate New Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  bool _isAppNameValid() {
    return appNameController.text.isNotEmpty;
  }

  bool _isPasswordValid() {
    return passwordController.text.isNotEmpty;
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one digit.';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return 'Password must contain at least one special character (!@#\$&*~).';
    }
    return null;
  }
}
