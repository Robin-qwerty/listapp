import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:sqflite/sqflite.dart';

class SettingsPage extends StatelessWidget {
  final String? userId;

  SettingsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Settings Page',
              textAlign: TextAlign.center,
            ),
            if (userId != null && userId != "0")
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AccountSettingsPage(userId: userId!),
                    ),
                  );
                },
                child: const Text('Account'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocalListsAndItemsPage(),
                  ),
                );
              },
              child: const Text('Local Lists and Items'),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountSettingsPage extends StatelessWidget {
  final String userId;

  AccountSettingsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Account Settings Page',
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () async {
                bool confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmation'),
                    content: const Text(
                        'Are you sure you want to delete your account? \nAll your account data, lists and items wil be deleted, This can\'t be reversed'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final response = await http.post(
                    Uri.parse(
                        'https://robin.humilis.net/flutter/listapp/delete_my_account.php?deleteuser=true'),
                    body: {'userId': userId},
                  );
                  final responseData = jsonDecode(response.body);
                  if (response.statusCode == 200) {
                    if (responseData['success'] == true) {
                      const storage = FlutterSecureStorage();
                      await storage.delete(key: 'userId');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted successfully.'),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Failed to delete account, please contact the owner of the app to report this! \nYou can try deleting your account at https://robin.humilis.net/flutter/listapp/delete_my_account.php'),
                          duration: Duration(seconds: 6),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Failed to delete account, please contact the owner of the app to report this! \nYou can try deleting your account at https://robin.humilis.net/flutter/listapp/delete_my_account.php'),
                        duration: Duration(seconds: 6),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalListsAndItemsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Lists and Items'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  bool confirmed = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmation'),
                      content: const Text(
                          'Are you sure you want to clear the local database? \nAll lists and items wil be delete for ever from this device!'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await clearLocalDatabase();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Local database cleared successfully.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Clear Local Database',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> clearLocalDatabase() async {
    final database = await _initDatabase();
    await database.delete('lists');
    await database.delete('items');
  }

  Future<Database> _initDatabase() async {
    try {
      return await openDatabase(
        'my_lists.db',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE lists (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              archive TINYINT NOT NULL DEFAULT 0,
              uploaded TINYINT NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE items (
              id INTEGER PRIMARY KEY,
              listid INTEGER NOT NULL,
              item_name TEXT NOT NULL,
              archive TINYINT NOT NULL DEFAULT 0,
              uploaded TINYINT NOT NULL DEFAULT 0
            )
          ''');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      throw e;
    }
  }
}

// class ChangePasswordPage extends StatelessWidget {
//   final String userId;

//   ChangePasswordPage({required this.userId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Change Password'),
//       ),
//       body: const Center(
//         child: Text('Change Password Page'),
//       ),
//     );
//   }
// }

// class ChangeUsernamePage extends StatelessWidget {
//   final String userId;

//   ChangeUsernamePage({required this.userId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Change Username'),
//       ),
//       body: const Center(
//         child: Text('Change Username Page'),
//       ),
//     );
//   }
// }

class DeleteAccountPage extends StatelessWidget {
  final String userId;

  DeleteAccountPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: const Center(
        child: Text('Delete Account Page'),
      ),
    );
  }
}
