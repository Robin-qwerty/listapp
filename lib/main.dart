import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'accountlesslists.dart';
import 'GroupLists.dart';
import 'login.dart';
import 'lists.dart';

void main() {
  print("main");
  runApp(MyApp());
}

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Home Screen')),
      ),
      routes: [
        GoRoute(
          path: 'details',
          builder: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Details Screen')),
          ),
        ),
      ],
    ),
  ],
);

void deleteUserId() async {
  final storage = FlutterSecureStorage();
  await storage.delete(key: 'userId');
  print("deleteUserId");
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = const FlutterSecureStorage();

  late Future<bool> _loggedInFuture;

  @override
  void initState() {
    super.initState();
    _loggedInFuture = _checkLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    print("build1");
    return MaterialApp(
      title: 'Login App',
      home: FutureBuilder(
        future: _loggedInFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            if (snapshot.data == true) {
              return MainApp();
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              });
              print("build2");
              return Container();
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkLoggedIn() async {
    print("_checkLoggedIn");
    try {
      final userId = await storage.read(key: 'userId');
      print('User ID from secure storage: $userId');
      return userId != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  String? userId;

  @override
  void initState() {
    print("initState");
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    print("_loadUserId");
    final storage = FlutterSecureStorage();
    userId = await storage.read(key: 'userId');
    setState(() {});
  }

  void _logout(BuildContext context) async {
    deleteUserId();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      if (userId != '0') MyLists(userId: userId ?? ''),
      if (userId != '0') MyGroupLists(userId: userId ?? ''),
      if (userId == '0') MyAccountlessLists(userId: userId ?? ''),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("List app"),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: userId != '0'
          ? BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'My lists',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: 'Group lists',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            )
          : null,
      drawer: userId != '0'
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Text('Menu'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
