import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class ListItemsPage extends StatefulWidget {
  final String userId;
  final int listId;
  final String listName;

  ListItemsPage(
      {required this.userId, required this.listId, required this.listName});

  @override
  _ListItemsPageState createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  TextEditingController _itemNameController = TextEditingController();
  FocusNode _itemNameFocusNode = FocusNode();
  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((database) {
      _database = database;
      _fetchItems();
    });
  }

  Future<Database> _initDatabase() async {
    try {
      return await openDatabase(
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
    } catch (e) {
      print('Error initializing database: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNameFocusNode.dispose();
    _database.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    // Fetch items from the local database
    final List<Map<String, dynamic>> items = await _database.query(
      'items',
      where: 'list_id = ?',
      whereArgs: [widget.listId],
    );
    return items;
  }

  Future<void> _editItem(
      BuildContext context, int itemId, String itemName) async {
    TextEditingController _itemNameController =
        TextEditingController(text: itemName);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: TextField(
            controller: _itemNameController,
            decoration: const InputDecoration(hintText: 'Enter New Item Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Update item from list in localdatabase
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateItemArchive(
      BuildContext context, int itemId, int archiveStatus) async {
    // update archive status of list item in localdatabase
  }

  List<Widget> _buildSlidableActions(
      BuildContext context, Map<String, dynamic> item) {
    if (item['archive'] == 0) {
      return [
        SlidableAction(
          onPressed: (context) {
            if (item['item_name'] != null) {
              _editItem(context, item['id'], item['item_name']);
            } else {
              print('Item name is null');
            }
          },
          backgroundColor: Colors.orange,
          icon: Icons.edit_outlined,
        ),
        SlidableAction(
          onPressed: (context) {
            // Handle check action
            _updateItemArchive(context, item['id'], 1);
          },
          backgroundColor: Colors.green,
          icon: Icons.check,
        ),
      ];
    } else if (item['archive'] == 1) {
      return [
        SlidableAction(
          onPressed: (context) {
            // Handle restore action
            _updateItemArchive(context, item['id'], 0);
          },
          backgroundColor: Colors.green,
          icon: Icons.restore,
        ),
        SlidableAction(
          onPressed: (context) {
            // Handle delete action
            _updateItemArchive(context, item['id'], 2);
          },
          backgroundColor: Colors.red,
          icon: Icons.delete,
        ),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Future<void> _addItem(String itemName) async {
      try {} catch (e) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to add list item, Please try again later'),
            duration: Duration(seconds: 3),
          ),
        );
        print('Error: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              FocusScope.of(context).requestFocus(_itemNameFocusNode);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Add New Item'),
                    content: TextField(
                      controller: _itemNameController,
                      focusNode: _itemNameFocusNode,
                      decoration:
                          const InputDecoration(hintText: 'Enter Item Name'),
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
                        onPressed: _itemNameController.text.isEmpty
                            ? null
                            : () {
                                _addItem(_itemNameController.text);
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items in this list.'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length + 1,
              itemBuilder: (context, index) {
                if (index == snapshot.data!.length) {
                  return const ListTile(
                    leading: Icon(Icons.swipe),
                    title:
                        Text('Swipe left or right to edit or delete an item'),
                    dense: true,
                  );
                } else {
                  final item = snapshot.data![index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Slidable(
                      startActionPane: ActionPane(
                        motion: DrawerMotion(),
                        children: _buildSlidableActions(context, item),
                      ),
                      endActionPane: ActionPane(
                        motion: DrawerMotion(),
                        children: _buildSlidableActions(context, item),
                      ),
                      child: ListTile(
                        tileColor: item['archive'] == 1
                            ? Colors.grey[150]
                            : Colors.grey[300],
                        title: Text(
                          item['item_name'].toString(),
                          style: TextStyle(
                            decoration: item['archive'] == 1
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        leading: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
