import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'lists.dart';

void main() {
  runApp(MyApp());
}

void deleteUserId() async {
  final storage = FlutterSecureStorage();
  await storage.delete(key: 'userId');
}

class MyApp extends StatelessWidget {
  final storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      home: FutureBuilder(
        future: _checkLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            if (snapshot.data == true) {
              // User is logged in, return the main app structure
              return MainApp();
            } else {
              // User is not logged in, navigate to the login page
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          LoginPage()), // Use LoginPage from login.dart
                );
              });
              return Container(); // Placeholder while navigating
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkLoggedIn() async {
    final userId = await storage.read(key: 'userId');
    print('User ID from secure storage1: $userId');
    return userId != null;
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  String? userId; // Declare userId as a class member

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load userId when MainApp is initialized
  }

  Future<void> _loadUserId() async {
    final storage = FlutterSecureStorage();
    userId = await storage.read(key: 'userId');
    setState(() {}); // Trigger rebuild to reflect userId changes
  }

  // Function to handle logout
  void _logout(BuildContext context) async {
    deleteUserId(); // Clear user ID from secure storage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("List app"),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MyLists(userId: userId ?? ''),
          // Groups(userId: userId ?? ''),
          Groups(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Group lists',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.place),
          //   label: 'stuff',
          // ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Update the index when a bottom navigation item is tapped
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      drawer: Drawer(
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
      ),
    );
  }
}

class Groups extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Group lists \n nothing here yet'),
    );
  }
}
