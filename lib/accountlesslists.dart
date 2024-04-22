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
  final FocusNode _listNameaddFocusNode = FocusNode();
  bool isLoading = false;

  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((database) {
      _dumpDatabase(database);
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
              last_opened INTEGER DEFAULT 0,
              archive TINYINT NOT NULL DEFAULT 0,
              uploaded TINYINT NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE items (
              id INTEGER PRIMARY KEY,
              listid INTEGER NOT NULL,
              item_name TEXT NOT NULL,
              stared TINYINT NOT NULL DEFAULT 0,
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

  Future<List<Map<String, dynamic>>> _fetchLists() async {
    await _initDatabase();
    final List<Map<String, dynamic>> lists = await _database.query(
      'lists',
      orderBy: 'last_opened DESC',
    );
    return lists;
  }

  Future<void> _addList(String listName) async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.userId == '0') {
      try {
        await _database.insert(
          'lists',
          {
            'name': listName,
            'uploaded': 2,
          },
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
    final messenger = ScaffoldMessenger.of(context);

    ScaffoldMessenger.of(context);
    return [
      SlidableAction(
        onPressed: (context) async {
          String? editedName = await showDialog(
            context: context,
            builder: (context) {
              TextEditingController _editListNameController =
                  TextEditingController(text: list['name']);
              FocusNode _focusNode = FocusNode();

              void setFocusToEnd() {
                _focusNode.requestFocus();
                _editListNameController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _editListNameController.text.length));
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                setFocusToEnd();
              });

              return AlertDialog(
                title: const Text('Edit List Name'),
                content: TextField(
                  controller: _editListNameController,
                  focusNode: _focusNode,
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

          final Database database = await _initDatabase();
          if (editedName != null && editedName.isNotEmpty) {
            try {
              await database.update(
                'lists',
                {
                  'name': editedName,
                },
                where: 'id = ?',
                whereArgs: [list['id']],
              );

              setState(() {});
              _listNameaddController.clear();
            } catch (e) {
              print('Error inserting list into database: $e');
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to edit list into the local database'),
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
          await showDialog(
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
                          'items',
                          where: 'listid = ?',
                          whereArgs: [list['id']],
                        );
                        await _database.delete(
                          'lists',
                          where: 'id = ?',
                          whereArgs: [list['id']],
                        );

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('List deleted!'),
                            duration: Duration(seconds: 3),
                          ),
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
                      print(
                          'Database is closed. Unable to delete list. try restarting the app.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Database is closed. Unable to delete list. try restarting the app.'),
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
                            onTap: () async {
                              final Database database = await _initDatabase();
                              int posixTime =
                                  DateTime.now().millisecondsSinceEpoch ~/ 1000;

                              await database.update(
                                'lists',
                                {'last_opened': posixTime},
                                where: 'id = ?',
                                whereArgs: [list['id']],
                              );

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
                              setState(() {});
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
