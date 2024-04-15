import 'package:flutter/material.dart';

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
            if (userId != null)
              ElevatedButton(
                onPressed: () {
                  // Navigate to account settings page
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
              onPressed: () {
                // Navigate to change password page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(userId: userId),
                  ),
                );
              },
              child: const Text('Change Password'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to change username page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeUsernamePage(userId: userId),
                  ),
                );
              },
              child: const Text('Change Username'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to delete account page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeleteAccountPage(userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete Account',
                style:
                    TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatelessWidget {
  final String userId;

  ChangePasswordPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: const Center(
        child: Text('Change Password Page'),
      ),
    );
  }
}

class ChangeUsernamePage extends StatelessWidget {
  final String userId;

  ChangeUsernamePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Username'),
      ),
      body: const Center(
        child: Text('Change Username Page'),
      ),
    );
  }
}

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
