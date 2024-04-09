import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'accountlesslistitempage.dart';
import 'main.dart';

class MyAccountlessLists extends StatefulWidget {
  final String userId;

  const MyAccountlessLists({required this.userId});

  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<MyAccountlessLists> {
  final TextEditingController _listNameController = TextEditingController();
  final FocusNode _listNameFocusNode = FocusNode();
  bool isLoading = false;

  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    print('_initDatabase');
    // Open the database or create if not exists
    _database = await openDatabase(
      'my_lists.db',
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        await db.execute('''
        CREATE TABLE lists (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          archive INTEGER NOT NULL DEFAULT 0
        )
        ''');
        await db.execute('''
        CREATE TABLE items (
          id INTEGER PRIMARY KEY,
          list_id INTEGER NOT NULL,
          item_name TEXT NOT NULL,
          archive INTEGER NOT NULL DEFAULT 0
        )
        ''');
      },
    );
  }

  @override
  void dispose() {
    _listNameController.dispose();
    _listNameFocusNode.dispose();
    if (widget.userId == '0') {
      _database.close();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchLists() async {
    // Ensure _database is initialized
    await _initDatabase();
    // Fetch lists from the local database
    final List<Map<String, dynamic>> lists = await _database.query('lists');
    return lists;
  }

  Future<void> _addList(String listName) async {
    if (widget.userId == '0') {
      // Add a list to the local database
      await _database.insert(
        'lists',
        {'name': listName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Refresh the UI
      setState(() {});
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    }
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
                    onPressed: () async {
                      if (_editListNameController.text.isNotEmpty) {
                        await _database.update(
                          'lists',
                          {'name': _editListNameController.text},
                          where: 'id = ?',
                          whereArgs: [list['id']],
                        );
                        setState(() {});
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );

          // Update the list name in the local database
          if (editedName != null && editedName.isNotEmpty) {
            // Update the list name in the local database
            // This logic is now handled inside the Save button onPressed callback
          }
        },
        backgroundColor: Colors.orange,
        icon: Icons.create_outlined,
      ),
      SlidableAction(
        onPressed: (context) async {
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
                  onPressed: () async {
                    await _database.delete(
                      'lists',
                      where: 'id = ?',
                      whereArgs: [list['id']],
                    );
                    setState(() {});
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          // Delete a list from the local database
          if (confirmDelete == true) {
            // Delete a list from the local database
            // This logic is now handled inside the Delete button onPressed callback
          }
        },
        backgroundColor: Colors.red,
        icon: Icons.delete,
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
              future: _fetchLists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print(snapshot.error);
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
