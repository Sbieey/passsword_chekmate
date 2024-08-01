import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/password_service.dart';
import '../utils/password_generator.dart';

class PasswordList extends StatefulWidget {
  @override
  _PasswordListState createState() => _PasswordListState();
}

class _PasswordListState extends State<PasswordList> {
  final PasswordService _passwordService = PasswordService();
  late Future<Map<String, String>> _passwordsFuture;
  Map<String, bool> _passwordVisibility = {};
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  TextEditingController searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _passwordsFuture = _passwordService.getPasswords();
    _authenticate();
    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text;
      });
    });
  }

  Future<void> _authenticate() async {
    try {
      _isAuthenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to view your passwords',
        options: AuthenticationOptions(biometricOnly: true),
      );
      setState(() {});
      if (_isAuthenticated) {
        setState(() {
          _passwordsFuture = _passwordService.getPasswords();
        });
      }
    } on PlatformException catch (e) {
      print('Authentication error: $e');
      setState(() {
        _isAuthenticated = false;
      });
    } catch (e) {
      print('Unknown error: $e');
      setState(() {
        _isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stored Passwords'),
        actions: [
          Icon(
            _isAuthenticated ? Icons.lock_open : Icons.lock_outline,
            color: _isAuthenticated ? Colors.green : Colors.red,
          ),
        ],
      ),
      body: _isAuthenticated
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, String>>(
                    future: _passwordsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No passwords stored.'));
                      } else {
                        final filteredPasswords = snapshot.data!.entries
                            .where((entry) => entry.key
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .toList();

                        filteredPasswords.forEach((entry) {
                          _passwordVisibility.putIfAbsent(
                              entry.key, () => false);
                        });

                        return ListView(
                          children: filteredPasswords.map((entry) {
                            return ListTile(
                              title: Text(entry.key),
                              subtitle: Text(_passwordVisibility[entry.key]!
                                  ? entry.value
                                  : '********'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: entry.value));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Password copied to clipboard')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(_passwordVisibility[entry.key]!
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisibility[entry.key] =
                                            !_passwordVisibility[entry.key]!;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () =>
                                        _showEditDialog(context, entry.key),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () =>
                                        _deletePassword(context, entry.key),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Please authenticate to view your passwords'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: Text('Retry Authentication'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, String appName) async {
    TextEditingController newPasswordController = TextEditingController();
    bool _passwordVisible = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Password for $appName'),
          content: TextField(
            controller: newPasswordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
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
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
                child: Text('Generate Password'),
                onPressed: () => {
                      newPasswordController.text = PasswordGenerator.generate()
                    }),
            TextButton(
              onPressed: () async {
                String? validationError =
                    _validatePassword(newPasswordController.text);
                String newPassword = newPasswordController.text;
                if (newPassword.isNotEmpty) {
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
                  await _passwordService.updatePassword(appName, newPassword);
                  setState(() {
                    _passwordsFuture = _passwordService.getPasswords();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePassword(BuildContext context, String appName) async {
    await _passwordService.deletePassword(appName);
    setState(() {
      _passwordsFuture = _passwordService.getPasswords();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password for $appName deleted')),
    );
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
