import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share/share.dart';
import 'listitempage.dart';
import 'dart:convert';

class MyLists extends StatefulWidget {
  final String userId;

  const MyLists({required this.userId});

  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<MyLists> {
  final TextEditingController _listNameController = TextEditingController();
  final FocusNode _listNameFocusNode = FocusNode();
  bool isLoading = false;

  @override
  void dispose() {
    _listNameController.dispose();
    _listNameFocusNode.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    _initDatabase().then((database) {
      _dumpDatabase(database);
      _checkConnectivityAndFetchLists();
    });
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

  void _dumpDatabase(Database database) async {
    final List<Map<String, dynamic>> localLists = await database.query('lists');
    final List<Map<String, dynamic>> localItems = await database.query('items');

    print('Lists:');
    localLists.forEach((list) => print(list));
    print('Items:');
    localItems.forEach((item) => print(item));
  }

  Future<List<Map<String, dynamic>>>? _checkConnectivityAndFetchLists() async {
    final messenger = ScaffoldMessenger.of(context);
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to Connect to the internet, changes won\'t be saved online and can\'t access group lists.'),
          duration: Duration(seconds: 3),
        ),
      );
      return _fetchListsFromLocal();
    } else {
      return _fetchListsFromWeb();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchListsFromLocal() async {
    final Database database = await _initDatabase();
    final List<Map<String, dynamic>> localLists = await database.query('lists');
    return localLists;
  }

  Future<List<Map<String, dynamic>>> _fetchListsFromWeb() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.get(Uri.parse(
          'https://robin.humilis.net/flutter/listapp/mylist.php?userid=${widget.userId}'));
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> webLists =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        final Database database = await _initDatabase();

        await database.delete('lists');

        for (final list in webLists) {
          await database.insert('lists', list,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        return webLists;
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to load lists'),
            duration: Duration(seconds: 3),
          ),
        );
        throw Exception('Failed to load lists');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _addList(String listName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/add_list.php'),
        body: {'userId': widget.userId, 'listName': listName},
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData['message'] == 'List added successfully') {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('List added successfully'),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {});
          _listNameController.clear();
          // print('Response: ${response.body}');
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('List added Failed, Please try again later'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('List added Failed, Please try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> generateLinkAndShare(listId) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse(
          'https://robin.humilis.net/flutter/listapp/generate_share_link.php'),
      body: {'userId': widget.userId, 'listId': listId},
    );

    if (response.statusCode == 200) {
      // print('Response: ${response.body}');
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Group code generated successfully'),
            duration: Duration(seconds: 3),
          ),
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Share List Link'),
              content: Text(responseData['link']),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: responseData['link']));
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Copy link'),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: responseData['code']));
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('code copied to clipboard'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Copy group code'),
                ),
                TextButton(
                  onPressed: () {
                    Share.share(
                        'Do you want to join my list group? \nHere is the link: ' +
                            responseData['link'] +
                            '\n Or you can use ' +
                            responseData['code']);
                    Navigator.pop(context);
                  },
                  child: const Text('Share'),
                ),
              ],
            );
          },
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong, Please try again later'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Widget> _buildSlidableActions(
      BuildContext context, Map<String, dynamic> list) {
    final messenger = ScaffoldMessenger.of(context);
    return [
      SlidableAction(
        onPressed: (context) async {
          String? editedName = await showDialog(
            context: context,
            builder: (context) {
              TextEditingController _editListNameController =
                  TextEditingController(text: list['name']);
              return AlertDialog(
                title: const Text('Edit List Name'),
                content: TextField(
                  controller: _editListNameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter List Name'),
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
              Uri.parse(
                  'https://robin.humilis.net/flutter/listapp/update_list.php'),
              body: {
                'userId': widget.userId,
                'listId': list['id'].toString(),
                'listName': editedName
              },
            );
            final responseData = jsonDecode(response.body);
            if (response.statusCode == 200) {
              if (responseData['success'] == true) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('List updated successfully'),
                    duration: Duration(seconds: 3),
                  ),
                );
                setState(() {});
                _listNameController.clear();
                // print('Response: ${response.body}');
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Failed to update lists name, Please try again later'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Failed to update lists name, Please try again later'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
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
              Uri.parse(
                  'https://robin.humilis.net/flutter/listapp/delete_list.php'),
              body: {'userId': widget.userId, 'listId': list['id'].toString()},
            );
            final responseData = jsonDecode(response.body);
            if (response.statusCode == 200) {
              if (responseData['success'] == true) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('List deleted successfully'),
                    duration: Duration(seconds: 3),
                  ),
                );
                setState(() {});
                _listNameController.clear();
                // print('Response: ${response.body}');
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Failed to delete this list, Please try again later'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Failed to delete this list, Please try again later'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        backgroundColor: Colors.red,
        icon: Icons.delete,
      ),
      SlidableAction(
        onPressed: (context) async {
          generateLinkAndShare(list['id'].toString());
        },
        backgroundColor: Colors.blue,
        icon: Icons.share,
      ),
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
              FocusScope.of(context).requestFocus(_listNameFocusNode);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Create a new list'),
                    content: TextField(
                      controller: _listNameController,
                      focusNode: _listNameFocusNode,
                      decoration:
                          const InputDecoration(hintText: 'Enter List Name'),
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
              future: _checkConnectivityAndFetchLists(),
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
                          Icons.playlist_remove,
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
                          motion: const DrawerMotion(),
                          children: _buildSlidableActions(context, list),
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
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
          const ListTile(
            leading: Icon(Icons.swipe),
            title:
                Text('Swipe left or right to edit, delete or \n share a lists'),
          ),
        ],
      ),
    );
  }
}
