import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/get_users.php'),
      body: {'userId': widget.userId, 'listId': widget.listId},
    );

    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
        users = filteredUsers = jsonDecode(response.body);
      });
    } else {
      setState(() {
        isLoading = false;
      });
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

  Future<void> shareList(String inviteUserId) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/share_list.php'),
      body: {
        'userId': widget.userId,
        'listId': widget.listId,
        'inviteUserId': inviteUserId,
      },
    );

    if (response.statusCode == 200) {
      print('Response: ${response.body}');
      final responseData = jsonDecode(response.body); // Decode JSON response
      if (responseData['message'] == 'List shared successfully') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('List shared successfully'),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true); // Pass true indicating success
      }
    } else {
      print('Failed to send share list request');
    }

    setState(() {
      isLoading = false;
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        title: Text(user['username']),
                        onTap: () => shareList(user['userid'].toString()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
