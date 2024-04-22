import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'listitempage.dart';
import 'dart:convert';

class MyGroupLists extends StatefulWidget {
  final String userId;

  MyGroupLists({required this.userId});

  @override
  _MyGroupListsState createState() => _MyGroupListsState();
}

class _MyGroupListsState extends State<MyGroupLists> {
  final TextEditingController _groupCodeController = TextEditingController();
  final FocusNode _groupCodeFocusNode = FocusNode();

  @override
  void dispose() {
    _groupCodeController.dispose();
    _groupCodeFocusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchGroupLists() async {
    final messenger = ScaffoldMessenger.of(context);
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return [];
    } else {
      final response = await http.post(
        Uri.parse(
            'https://robin.humilis.net/flutter/listapp/get_group_lists.php'),
        body: {'userId': widget.userId},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('Failed to get your group lists, Please try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception('Failed to fetch group lists');
      }
    }
  }

  Future<void> _joinGroup(String groupCode) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/join_group.php'),
        body: {'userId': widget.userId, 'groupCode': groupCode},
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData['message'] == 'Joined group successfully') {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Joined group successfully'),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {});
          _groupCodeController.clear();
          // print('Response: ${response.body}');
        } else if (responseData['message'] ==
            'User is already a member of this group') {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('You are already a member of this group'),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {});
          _groupCodeController.clear();
          // print('Response: ${response.body}');
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to join group, Please try again later'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to join group, Please try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong, Please try again later'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  List<Widget> _buildSlidableActions(
      BuildContext context, Map<String, dynamic> list) {
    final messenger = ScaffoldMessenger.of(context);
    return [
      SlidableAction(
        onPressed: (context) async {
          bool confirmLeave = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Leave'),
              content:
                  const Text('Are you sure you want to leave this group list?'),
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
            final response = await http.post(
              Uri.parse(
                  'https://robin.humilis.net/flutter/listapp/leave_group_list.php'),
              body: {'userId': widget.userId, 'listId': list['id'].toString()},
            );
            // print('Response: ${response.body}');
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
                    content: Text(
                        'Failed to leave the group list, Please try again later'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              setState(() {});
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Failed to leave the group list, Please try again later'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        backgroundColor: Colors.red,
        icon: Icons.exit_to_app,
      ),
      SlidableAction(
        onPressed: (context) async {
            final response = await http.post(
              Uri.parse(
                  'https://robin.humilis.net/flutter/listapp/group_user_list.php'),
              body: {'userId': widget.userId, 'listId': list['id'].toString()},
            );
            // print('Response: ${response.body}');
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
                    content: Text(
                        'Something went wrong when trying to load group users, Please try again later'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              setState(() {});
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Failed to load group users, Please try again later'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
        },
        backgroundColor: Colors.blue,
        icon: Icons.groups,
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
        heroTag: 'add_group_list',
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              FocusScope.of(context).requestFocus(_groupCodeFocusNode);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Join a group list with a code'),
                    content: TextField(
                      controller: _groupCodeController,
                      focusNode: _groupCodeFocusNode,
                      decoration:
                          const InputDecoration(hintText: 'Enter group code'),
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
                        onPressed: _groupCodeController.text.isEmpty
                            ? null
                            : () {
                                _joinGroup(_groupCodeController.text);
                                Navigator.pop(context);
                              },
                        child: const Text('join'),
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
              future: _fetchGroupLists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('You don\'t have any group lists.'),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final list = snapshot.data![index];
                      final sharedWithCount = list['shared_with_count'];

                      return Slidable(
                        startActionPane: ActionPane(
                          motion: DrawerMotion(),
                          extentRatio: 0.2,
                          children: _buildSlidableActions(context, list),
                        ),
                        endActionPane: ActionPane(
                          motion: DrawerMotion(),
                          extentRatio: 0.2,
                          children: _buildSlidableActions(context, list),
                        ),
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    list['name'].toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (sharedWithCount != null &&
                                    sharedWithCount > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.group,
                                          color: Colors.grey, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '($sharedWithCount)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListItemsPage(
                                    userId: widget.userId,
                                    listId: list['id'],
                                    listUserId: list['userid'],
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
          const ListTile(
            leading: Icon(Icons.swipe),
            title: Text('Swipe left or right to Leave a list'),
          ),
        ],
      ),
    );
  }
}
