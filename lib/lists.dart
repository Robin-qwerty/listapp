import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'listitempage.dart';

class MyLists extends StatefulWidget {
  final String userId;

  MyLists({required this.userId});

  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<MyLists> {
  TextEditingController _listNameController = TextEditingController();
  FocusNode _listNameFocusNode = FocusNode();

  @override
  void dispose() {
    _listNameController.dispose();
    _listNameFocusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchLists() async {
    final response = await http.get(Uri.parse(
        'https://robin.humilis.net/flutter/listapp/mylist.php?userid=${widget.userId}'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load lists');
    }
  }

  Future<void> _addList(String listName) async {
    try {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/add_list.php'),
        body: {'userId': widget.userId, 'listName': listName},
      );
      if (response.statusCode == 200) {
        // Refresh the list after adding the new one
        setState(() {});
        _listNameController.clear();
        print('Response: ${response.body}');
      } else {
        throw Exception('Failed to add list');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  List<Widget> _buildSlidableActions(BuildContext context, Map<String, dynamic> list) {
    return [
      SlidableAction(
        onPressed: (context) async {
          // Show dialog to edit list name
          String? editedName = await showDialog(
            context: context,
            builder: (context) {
              TextEditingController _editListNameController = TextEditingController(text: list['name']);
              return AlertDialog(
                title: const Text('Edit List Name'),
                content: TextField(
                  controller: _editListNameController,
                  decoration: const InputDecoration(hintText: 'Enter List Name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, _editListNameController.text);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );

          if (editedName != null && editedName.isNotEmpty) {
            // Send a web request to update the list name
            final response = await http.post(
              Uri.parse('https://robin.humilis.net/flutter/listapp/update_list.php'),
              body: {'userId': widget.userId, 'listId': list['id'].toString(), 'listName': editedName},
            );
            if (response.statusCode == 200) {
              // Refresh the list after updating the list name
              setState(() {});
              print('Response: ${response.body}');
            } else {
              throw Exception('Failed to update list name');
            }
          }
        },
        backgroundColor: Colors.orange,
        icon: Icons.create_outlined,
      ),
      SlidableAction(
        onPressed: (context) async {
          // Show confirmation dialog
          bool confirmDelete = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this list?'),
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
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmDelete == true) {
            // Send a web request to delete the list
            final response = await http.post(
              Uri.parse('https://robin.humilis.net/flutter/listapp/delete_list.php'),
              body: {'userId': widget.userId, 'listId': list['id'].toString()},
            );
            if (response.statusCode == 200) {
              // Refresh the list after deleting the list
              setState(() {});
              // Print the response body
              print('Response: ${response.body}');
            } else {
              throw Exception('Failed to delete list');
            }
          }
        },
        backgroundColor: Colors.red,
        icon: Icons.delete,
      ),
      SlidableAction(
        onPressed: (context) {
          // Placeholder action for sharing
          // Implement sharing functionality here
        },
        backgroundColor: Colors.blue,
        icon: Icons.share,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              // Automatically focus on the text input and open keyboard
              FocusScope.of(context).requestFocus(_listNameFocusNode);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Create a new list'),
                    content: TextField(
                      controller: _listNameController,
                      focusNode: _listNameFocusNode,
                      decoration: const InputDecoration(hintText: 'Enter List Name'),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: _listNameController.text.isEmpty
                            ? null
                            : () {
                                _addList(_listNameController.text);
                                Navigator.pop(context);
                              },
                        child: const Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.data!.isEmpty) {
                  // If the user has no lists
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add_check,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'You don\'t have any lists.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
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
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text(
                              list['name'].toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            title: Text('Swipe left or right to edit or delete lists'),
          ),
        ],
      ),
    );
  }
}
