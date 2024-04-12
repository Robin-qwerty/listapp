import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:connectivity/connectivity.dart';
import 'package:clipboard/clipboard.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

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
  final TextEditingController _itemNameController = TextEditingController();
  final FocusNode _itemNameFocusNode = FocusNode();

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNameFocusNode.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    _initDatabase().then((database) {
      _checkConnectivityAndFetchItems();
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

  Future<List<Map<String, dynamic>>>? _checkConnectivityAndFetchItems() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return _fetchItemsFromLocal();
    } else {
      return _fetchItems();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItemsFromLocal() async {
    final Database database = await _initDatabase();
    final List<Map<String, dynamic>> localLists = await database.query(
      'items',
      where: 'listid = ?',
      whereArgs: [widget.listId],
    );
    return localLists;
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return [];
    } else {
      final response = await http.post(
        Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
        body: {'userId': widget.userId, 'listId': widget.listId.toString()},
      );
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> webItems =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        final Database database = await _initDatabase();

        await database.delete('lists');

        for (final list in webItems) {
          await database.insert('items', list,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        return webItems;
      } else {
        throw Exception('Failed to load items');
      }
    }
  }

  Future<void> _editItem(
      BuildContext context, int itemId, String itemName) async {
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
                          'Failed to add list item, Please try again later'),
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
      BuildContext context, int itemId, int archiveStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
      body: {
        'userId': widget.userId,
        'itemId': itemId.toString(),
        'archiveStatus': archiveStatus.toString()
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
            _updateItemArchive(context, item['id'], 1);
          },
          backgroundColor: Colors.green,
          icon: Icons.check,
        ),
        SlidableAction(
          onPressed: (context) {
            FlutterClipboard.copy(item['item_name'].toString())
                .then((value) => print('Copied to clipboard'));
          },
          backgroundColor: Colors.blue,
          icon: Icons.content_copy,
        ),
      ];
    } else {
      return [
        SlidableAction(
          onPressed: (context) {
            _updateItemArchive(context, item['id'], 0);
          },
          backgroundColor: Colors.green,
          icon: Icons.restore,
        ),
        SlidableAction(
          onPressed: (context) {
            _updateItemArchive(context, item['id'], 2);
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
            // print('Response: ${response.body}');
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content:
                    Text('Failed to add list item, Please try again later'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to add list item, Please try again later'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to add list item, Please try again later'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
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
        future: _fetchItems(),
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
