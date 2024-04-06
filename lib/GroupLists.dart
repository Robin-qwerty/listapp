import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'listitempage.dart';

class MyGroupLists extends StatefulWidget {
  final String userId;

  MyGroupLists({required this.userId});

  @override
  _MyGroupListsState createState() => _MyGroupListsState();
}

class _MyGroupListsState extends State<MyGroupLists> {
  TextEditingController _listNameController = TextEditingController();
  FocusNode _listNameFocusNode = FocusNode();

  @override
  void dispose() {
    _listNameController.dispose();
    _listNameFocusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchGroupLists() async {
    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/get_group_lists.php'),
      body: {'userId': widget.userId},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch group lists');
    }
  }

  List<Widget> _buildSlidableActions(BuildContext context, Map<String, dynamic> list) {
  final messenger = ScaffoldMessenger.of(context);
  return [
    SlidableAction(
      onPressed: (context) async {
        bool confirmLeave = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Leave'),
            content: const Text('Are you sure you want to leave this group list?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Leave'),
              ),
            ],
          ),
        );

        if (confirmLeave == true) {
          // Send a web request to leave the group list
          final response = await http.post(
            Uri.parse('https://robin.humilis.net/flutter/listapp/leave_group_list.php'),
            body: {'userId': widget.userId, 'listId': list['id'].toString()},
          );
          print('Response: ${response.body}');
          if (response.statusCode == 200) {
            if (response.body == 'success') {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('You left the group list successfully.'),
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to leave the group list.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            setState(() {});
          } else {
            throw Exception('Failed to leave group list');
          }
        }
      },
      backgroundColor: Colors.red,
      icon: Icons.exit_to_app,
    ),
  ];
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Lists'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Add your onPressed logic for adding a new group list
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchGroupLists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.data!.isEmpty) {
                  // If the user has no group lists
                  return const Center(
                    child: Text('You don\'t have any group lists.'),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final list = snapshot.data![index];
                      return Slidable(
                        startActionPane: ActionPane(
                          motion: DrawerMotion(),
                          children: _buildSlidableActions(context, list),
                        ),
                        endActionPane: ActionPane(
                          motion: DrawerMotion(),
                          children: _buildSlidableActions(context, list),
                        ),
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text(
                              list['name'].toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListItemsPage(
                                    userId: widget.userId,
                                    listId: list['id'],
                                    listName: list['name'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          // Instructional ListTile
          const ListTile(
            leading: Icon(Icons.swipe),
            title: Text('Swipe left or right to perform actions'),
          ),
        ],
      ),
    );
  }
}
