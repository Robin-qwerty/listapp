import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserListPage extends StatefulWidget {
  final String userId;
  final String listId;

  UserListPage({required this.userId, required this.listId});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/get_users.php'),
      body: {'userId': widget.userId, 'listId': widget.listId},
    );

    if (response.statusCode == 200) {
      setState(() {
        users = filteredUsers = jsonDecode(response.body);
      });
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  void filterUsers(String query) {
    setState(() {
      filteredUsers = users
          .where((user) =>
              user['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterUsers,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  title: Text(user['username']),
                  onTap: () async {
                    final response = await http.post(
                      Uri.parse('https://robin.humilis.net/flutter/listapp/share_list.php'),
                      body: {
                        'userId': widget.userId,
                        'listId': widget.listId,
                        'inviteUserId': user['userid'].toString(), // Use user variable here
                      },
                    );
                    if (response.statusCode == 200) {
                      print('Share list request sent');
                      print('Response: ${response.body}');
                    } else {
                      print('Failed to send share list request');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
