import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:connectivity/connectivity.dart';
import 'package:clipboard/clipboard.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class ListItemsPage extends StatefulWidget {
  final String userId;
  final int? listUserId;
  final int listId;
  final String listName;

  ListItemsPage(
      {required this.userId,
      required this.listUserId,
      required this.listId,
      required this.listName});

  @override
  _ListItemsPageState createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  final TextEditingController _itemNameController = TextEditingController();
  final FocusNode _itemNameFocusNode = FocusNode();
  bool connected = true;

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNameFocusNode.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    _initDatabase().then((database) {});
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

  Future<List<Map<String, dynamic>>>? _checkConnectivityAndFetchItems() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      connected = false;
      return _fetchItemsFromLocal();
    } else {
      return _fetchItems();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItemsFromLocal() async {
    final Database database = await _initDatabase();
    final List<Map<String, dynamic>> localItems = await database.rawQuery('''
      SELECT * FROM items WHERE listid = ? AND archive != 2
      ORDER BY 
        CASE 
          WHEN stared = 1 AND archive = 0 THEN 0 
          WHEN archive = 0 THEN 1
          ELSE 2
        END, 
        id ASC
    ''', [widget.listId]);
    return localItems;
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    final Database database = await _initDatabase();
    ScaffoldMessenger.of(context);

    try {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
        body: {
          'userId': widget.userId,
          'listId': widget.listId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> webItems =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        for (final item in webItems) {
          await database.insert('items', item,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        return webItems;
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      connected = false;
      setState(() {});
      throw e;
    }
  }

  Future<void> _editItem(
      BuildContext context, int itemId, String itemName, item) async {
    TextEditingController itemNameController =
        TextEditingController(text: itemName);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: TextFormField(
            controller: itemNameController,
            autofocus: true,
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
                if (connected) {
                  try {
                    final response = await http.post(
                      Uri.parse(
                          'https://robin.humilis.net/flutter/listapp/list_items.php'),
                      body: {
                        'userId': widget.userId,
                        'itemId': itemId.toString(),
                        'itemName': itemNameController.text
                      },
                    );
                    // print('Response: ${response.body}');

                    if (response.statusCode == 200) {
                      setState(() {});
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Failed to edit list item, Please try again later'),
                          duration: Duration(seconds: 3),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    connected = false;
                    setState(() {});
                    throw e;
                  }
                }

                try {
                  final Database database = await _initDatabase();
                  await database.update(
                    'items',
                    {
                      'item_name': itemNameController.text,
                      'uploaded':
                          (item['uploaded'] == 2) ? 2 : (connected ? 0 : 1),
                    },
                    where: 'id = ?',
                    whereArgs: [itemId],
                  );

                  setState(() {});
                } catch (e) {
                  print('Error updating list item name in database: $e');
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Failed to update list item name in the local database (offline)'),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateItemArchive(
      BuildContext context, int itemId, int archiveStatus, item) async {
    final Database database = await _initDatabase();
    final messenger = ScaffoldMessenger.of(context);

    if (connected) {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
        body: {
          'userId': widget.userId,
          'itemId': itemId.toString(),
          'archiveStatus': archiveStatus.toString()
        },
      );
      // print('Response: ${response.body}');

      if (archiveStatus == 2) {
        await database.delete(
          'items',
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }

      if (response.statusCode == 200) {
        setState(() {});
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Something went wrong, Please try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      try {
        final Database database = await _initDatabase();
        await database.update(
          'items',
          {
            'archive': archiveStatus,
            'uploaded': (item['uploaded'] != 2) ? 1 : 2,
          },
          where: 'id = ?',
          whereArgs: [itemId],
        );

        setState(() {});
      } catch (e) {
        print('Error updating archive status of list item in database: $e');
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to update archive status of list item in the local database (offline)'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateItemStared(
      BuildContext context, int itemId, int staredStatus, item) async {
    final Database database = await _initDatabase();
    final messenger = ScaffoldMessenger.of(context);

    if (connected) {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
        body: {
          'userId': widget.userId,
          'itemId': itemId.toString(),
          'staredStatus': staredStatus.toString()
        },
      );
      // print('Response: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {});
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Something went wrong, Please try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    try {
      await database.update(
        'items',
        {
          'stared': staredStatus,
          'uploaded': (item['uploaded'] == 2) ? 2 : (connected ? 0 : 1),
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      setState(() {});
    } catch (e) {
      print(
          'Error updating archive status or stared state of list item in database: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to update archive status or stared state of list item in the local database (offline)'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildSlidableActions(
      BuildContext context, Map<String, dynamic> item) {
    final messenger = ScaffoldMessenger.of(context);
    if (item['archive'] == 0) {
      return [
        SlidableAction(
          onPressed: (context) {
            if (item['item_name'] != null) {
              _editItem(context, item['id'], item['item_name'], item);
            } else {
              print('Item name is null');
            }
          },
          backgroundColor: Colors.orange,
          icon: Icons.edit_outlined,
        ),
        SlidableAction(
          onPressed: (context) {
            _updateItemArchive(context, item['id'], 1, item);
          },
          backgroundColor: Colors.green,
          icon: Icons.check,
        ),
        SlidableAction(
          onPressed: (context) {
            int newStaredStatus = item['stared'] == 1 ? 0 : 1;
            _updateItemStared(context, item['id'], newStaredStatus, item);
          },
          backgroundColor: Colors.yellow,
          icon: item['stared'] == 1
              ? Icons.star_rate_rounded
              : Icons.star_border_rounded,
        ),
        SlidableAction(
          onPressed: (context) {
            FlutterClipboard.copy(item['item_name'].toString())
                .then((value) => messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Item copyed to clipboard'),
                        duration: Duration(seconds: 3),
                      ),
                    ));
          },
          backgroundColor: Colors.blue,
          icon: Icons.content_copy,
        ),
      ];
    } else {
      return [
        SlidableAction(
          onPressed: (context) {
            _updateItemArchive(context, item['id'], 0, item);
          },
          backgroundColor: Colors.green,
          icon: Icons.restore,
        ),
        SlidableAction(
          onPressed: (context) {
            _updateItemArchive(context, item['id'], 2, item);
          },
          backgroundColor: Colors.red,
          icon: Icons.delete,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Future<void> _addItem(String itemName) async {
      if (connected) {
        try {
          final response = await http.post(
            Uri.parse('https://robin.humilis.net/flutter/listapp/add_item.php'),
            body: {
              'userId': widget.userId,
              'listId': widget.listId.toString(),
              'itemName': itemName
            },
          );
          final responseData = jsonDecode(response.body);
          // print('Response: ${response.body}');
          if (response.statusCode == 200) {
            if (responseData['success'] == true) {
              setState(() {});
              _itemNameController.clear();
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content:
                      Text('Failed to add list item, Please try again later1'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content:
                    Text('Failed to add list item, Please try again later2'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to add list item, Please try again later3'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
          print('Error: $e');
        }
      }

      try {
        final Database database = await _initDatabase();
        await database.insert(
          'items',
          {
            'listid': widget.listId,
            'item_name': itemName,
            'archive': 0,
            'uploaded': connected ? 0 : 2,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        setState(() {});
        _itemNameController.clear();
      } catch (e) {
        print('Error inserting list item into database: $e');
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to insert list item in the local database (offline)'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_item',
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              FocusScope.of(context).requestFocus(_itemNameFocusNode);
              Future.delayed(const Duration(milliseconds: 100), () {
                _itemNameFocusNode.requestFocus();
              });
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
        future: _checkConnectivityAndFetchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
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
                        motion: const DrawerMotion(),
                        extentRatio: item['archive'] == 0 ? 0.70 : 0.35,
                        children: _buildSlidableActions(context, item),
                      ),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: item['archive'] == 0 ? 0.70 : 0.35,
                        children: _buildSlidableActions(context, item),
                      ),
                      child: ListTile(
                        tileColor: item['archive'] == 1
                            ? Colors.grey[150]
                            : Colors.grey[300],
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['item_name'].toString(),
                                style: TextStyle(
                                  decoration: item['archive'] == 1
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (item['stared'] == 1 && item['archive'] == 0)
                              const Icon(
                                Icons.star_rate_rounded,
                                color: Colors.black,
                              ),
                          ],
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
