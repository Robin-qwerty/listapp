import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main.dart';

void main() {
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Added
  final storage = FlutterSecureStorage();
  String _errorText = '';
  bool _isLogin = true;

  Future<void> _login(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Both fields are required';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/login.php'),
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final String responseBody = response.body;
      // print(responseBody);
      if (responseBody == "ERROR1") {
        setState(() {
          _errorText = 'Login failed. Please try again later.';
          _passwordController.clear();
        });
      } else if (responseBody == "ERROR2") {
        setState(() {
          _errorText =
              'Username and Password do not match. Please try again later.';
          _passwordController.clear();
        });
      } else if (responseBody == "ERROR3") {
        setState(() {
          _errorText = 'Both username and password are required.';
          _usernameController.clear();
          _passwordController.clear();
        });
      } else if (_isNumeric(responseBody)) {
        final userId = responseBody;

        print('Response from server: $responseBody');

        await storage.write(key: 'userId', value: userId);

        final storedUserId = await storage.read(key: 'userId');
        print('User ID stored in secure storage: $storedUserId');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainApp()),
        );
      } else {
        setState(() {
          _errorText =
              'There has been an unknown error. Please try again later.';
          _usernameController.clear();
          _passwordController.clear();
        });
      }
    } else {
      setState(() {
        _errorText = 'Failed to login. Please try again later.';
        _passwordController.clear();
      });
    }
  }

  Future<void> _register(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    // Check if both fields are filled in and passwords match
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorText = 'All fields are required';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorText = 'Passwords do not match';
      });
      return;
    }

    final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/register.php'),
        body: {'username': username, 'password': password});

    if (response.statusCode == 200) {
      final String responseBody = response.body;
      if (responseBody == "ERROR1") {
        setState(() {
          _errorText = 'Registration failed. Please try again.';
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else if (responseBody == "ERROR2") {
        setState(() {
          _errorText = 'Registration failed. Username already in use.';
          _usernameController.clear();
        });
      } else if (responseBody == "ERROR3") {
        setState(() {
          _errorText = 'Both username and password are required.';
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else if (_isNumeric(responseBody)) {
        final userId =
            responseBody;
        await storage.write(key: 'userId', value: userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainApp()),
        );
      } else {
        setState(() {
          _errorText =
              'There has been an unknown error. Please try again later.';
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } else {
      setState(() {
        _errorText = 'Failed to register. Please try again later.';
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    }
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration:
                  InputDecoration(labelText: 'Password', errorText: _errorText),
              obscureText: true,
            ),
            if (!_isLogin)
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isLogin ? () => _login(context) : () => _register(context),
              child: Text(_isLogin ? 'Login' : 'Register'),
            ),
            TextButton(
              onPressed: _toggleMode,
              child: Text(_isLogin
                  ? 'Create an account'
                  : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
