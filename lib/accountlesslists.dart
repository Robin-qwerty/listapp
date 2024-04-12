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
  final TextEditingController _listNameaddController = TextEditingController();
  final TextEditingController _listNameeditController = TextEditingController();
  final FocusNode _listNameaddFocusNode = FocusNode();
  final FocusNode _listNameeditFocusNode = FocusNode();
  bool isLoading = false;

  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((database) {
      _database = database;
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

  @override
  void dispose() {
    _listNameaddController.dispose();
    _listNameaddFocusNode.dispose();
    _listNameeditController.dispose();
    _listNameeditFocusNode.dispose();
    _database.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchLists() async {
    await _initDatabase();
    final List<Map<String, dynamic>> lists = await _database.query('lists');
    return lists;
  }

  Future<void> _addList(String listName) async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.userId == '0') {
      try {
        await _database.insert(
          'lists',
          {'name': listName},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        messenger.showSnackBar(
          const SnackBar(
            content: Text('List added!'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {});
        _listNameaddController.clear();
      } catch (e) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to add list, try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        throw e;
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    }
  }

  List<Widget> _buildSlidableActions(
      BuildContext context, Map<String, dynamic> list) {
    ScaffoldMessenger.of(context);
    return [
      SlidableAction(
        onPressed: (context) async {},
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
                    if (_database.isOpen) {
                      try {
                        await _database.delete(
                          'lists',
                          where: 'id = ?',
                          whereArgs: [list['id']],
                        );
                        setState(() {});
                        Navigator.of(context).pop(true);
                      } catch (error) {
                        print('Error deleting list: $error');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Failed to delete list. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      print('Database is closed. Unable to delete list.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Database is closed. Unable to delete list.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
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
        heroTag: 'add_list_accountless',
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              FocusScope.of(context).requestFocus(_listNameaddFocusNode);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Create a new list'),
                    content: TextField(
                      controller: _listNameaddController,
                      focusNode: _listNameaddFocusNode,
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
                        onPressed: _listNameaddController.text.isEmpty
                            ? null
                            : () {
                                _addList(_listNameaddController.text);
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
