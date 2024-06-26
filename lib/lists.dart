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
  bool connected = true;

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
    print('end database');
  }

  Future<List<Map<String, dynamic>>>? _checkConnectivityAndFetchLists() async {
    final messenger = ScaffoldMessenger.of(context);
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      connected = false;
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

    final List<Map<String, dynamic>> localLists = await database.query(
      'lists',
      where: 'archive = 0',
      orderBy: 'last_opened DESC',
    );

    return localLists;
  }

  Future<List<Map<String, dynamic>>> _fetchListsFromWeb() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final Database database = await _initDatabase();

      final List<Map<String, dynamic>> localLists = await database.query(
        'lists',
        where: 'uploaded != ?',
        whereArgs: [0],
      );

      final List<Map<String, dynamic>> localItems = await database.query(
        'items',
        where: 'uploaded != ?',
        whereArgs: [0],
      );

      if (localLists.isNotEmpty || localItems.isNotEmpty) {
        final List<Map<String, dynamic>> listsToSend = localLists.map((list) {
          return {
            'id': list['id'],
            'name': list['name'],
            'last_opened': list['last_opened'],
            'archive': list['archive'],
            'uploaded': list['uploaded'],
          };
        }).toList();

        final List<Map<String, dynamic>> itemsToSend = localItems.map((item) {
          return {
            'id': item['id'],
            'listid': item['listid'],
            'item_name': item['item_name'],
            'archive': item['archive'],
            'uploaded': item['uploaded'],
          };
        }).toList();

        try {
          final response = await http.post(
            Uri.parse('https://robin.humilis.net/flutter/listapp/upload.php'),
            body: {
              'userid': widget.userId,
              'lists': jsonEncode({'lists': listsToSend}),
              'items': jsonEncode({'items': itemsToSend}),
            },
          );
          // print('Response: ${response.body}');

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            if (responseData['success'] == true) {
              final List<String> changedListIds =
                  List<String>.from(responseData['changedListIds']);

              for (final idString in changedListIds) {
                int? id = int.tryParse(idString);
                if (id != null) {
                  await database.delete(
                    'lists',
                    where: 'id = ?',
                    whereArgs: [id],
                  );
                } else {
                  print('Invalid list ID: $idString');
                }
              }

              for (final list in localLists) {
                await database.update(
                  'lists',
                  {'uploaded': 0},
                  where: 'id = ?',
                  whereArgs: [list['id']],
                );
                await database.delete('lists', where: 'archive = 1');
                await database.delete('items', where: 'archive = 2');
              }

              for (final item in localItems) {
                await database.update(
                  'items',
                  {'uploaded': 0},
                  where: 'id = ?',
                  whereArgs: [item['id']],
                );
              }

              await database.delete(
                'lists',
                where: 'uploaded = 2',
              );
              await database.delete(
                'items',
                where: 'uploaded = 2',
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                      'Something went wrong when uploading lists and items'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content:
                    Text('Something went wrong when uploading lists and items'),
                duration: Duration(seconds: 5),
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
        final responselists = await http.post(
          Uri.parse('https://robin.humilis.net/flutter/listapp/mylist.php'),
          body: {
            'userid': widget.userId,
          },
        );

        if (responselists.statusCode == 200) {
          final List<Map<String, dynamic>> webLists =
              List<Map<String, dynamic>>.from(json.decode(responselists.body));

          for (final list in webLists) {
            final listWithoutUserId = Map<String, dynamic>.from(list);
            listWithoutUserId.remove('userid');
            listWithoutUserId.remove('shared_with_count');
            await database.insert('lists', listWithoutUserId,
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }

          return webLists;
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to load lists'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
          print('Failed to load lists');
          return [];
        }
      } catch (e) {
        connected = false;
        setState(() {});
        throw e;
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something really went wrong. Please try again later.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      throw e;
    }
  }

  Future<void> _addList(String listName) async {
    final messenger = ScaffoldMessenger.of(context);

    if (connected) {
      try {
        final response = await http.post(
          Uri.parse('https://robin.humilis.net/flutter/listapp/add_list.php'),
          body: {'userId': widget.userId, 'listName': listName},
        );
        // print('Response: ${response.body}');

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
        connected = false;
        setState(() {});
        throw e;
      }
    } else {
      final Database database = await _initDatabase();
      try {
        await database.insert('lists', {'name': listName, 'uploaded': 2});
        messenger.showSnackBar(
          const SnackBar(
            content: Text('List added successfully (offline)'),
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {});
        _listNameController.clear();
      } catch (e) {
        print('Error inserting list into database: $e');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to add list to the local database (offline)'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> generateLinkAndShare(listId) async {
    final messenger = ScaffoldMessenger.of(context);

    if (connected) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse(
              'https://robin.humilis.net/flutter/listapp/generate_share_link.php'),
          body: {'userId': widget.userId, 'listId': listId},
        );

        // print('Response: ${response.body}');

        if (response.statusCode == 200) {
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
      } catch (e) {
        connected = false;
        setState(() {});
        throw e;
      }

      setState(() {
        isLoading = false;
      });
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Can\'t share list when ofline'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildSlidableActions(
    BuildContext context,
    Map<String, dynamic> list,
  ) {
    ScaffoldMessenger.of(context);
    return [
      SlidableAction(
        onPressed: (context) {
          _editList(context, list['id'], list['name'], list);
        },
        backgroundColor: Colors.orange,
        icon: Icons.create_outlined,
      ),
      SlidableAction(
        onPressed: (context) {
          _updateListArchive(context, list['id'], 1, list);
        },
        backgroundColor: Colors.red,
        icon: Icons.delete,
      ),
      SlidableAction(
        onPressed: (context) {
          generateLinkAndShare(list['id'].toString());
        },
        backgroundColor: Colors.blue,
        icon: Icons.share,
      ),
    ];
  }

  Future<void> _editList(
    BuildContext context,
    int listId,
    String listName,
    Map<String, dynamic> list,
  ) async {
    TextEditingController editListNameController =
        TextEditingController(text: listName);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit List Name'),
          content: TextField(
            controller: editListNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter List Name'),
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
                          'https://robin.humilis.net/flutter/listapp/update_list.php'),
                      body: {
                        'userId': widget.userId,
                        'listId': listId.toString(),
                        'listName': editListNameController.text
                      },
                    );

                    final responseData = jsonDecode(response.body);

                    if (response.statusCode == 200 && responseData['success']) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('List updated successfully'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      setState(() {});
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Failed to update list, Please try again later'),
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
                    'lists',
                    {
                      'name': editListNameController.text,
                      'uploaded': (list['uploaded'] != 2) ? 1 : 2,
                    },
                    where: 'id = ?',
                    whereArgs: [listId],
                  );

                  setState(() {});
                } catch (e) {
                  print('Error updating list name in database: $e');
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Failed to update list name in the local database (offline)'),
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

  Future<void> _updateListArchive(
    BuildContext context,
    int listId,
    int archiveStatus,
    Map<String, dynamic> list,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final Database database = await _initDatabase();

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
      try {
        if (connected) {
          final response = await http.post(
            Uri.parse(
                'https://robin.humilis.net/flutter/listapp/delete_list.php'),
            body: {'userId': widget.userId, 'listId': listId.toString()},
          );

          final responseData = jsonDecode(response.body);

          if (response.statusCode == 200 && responseData['success']) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('List deleted successfully'),
                duration: Duration(seconds: 3),
              ),
            );

            await database.delete(
              'lists',
              where: 'id = ?',
              whereArgs: [listId],
            );

            setState(() {});
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Failed to delete list, Please try again later'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          await database.update(
            'lists',
            {
              'archive': archiveStatus,
              'uploaded': (list['uploaded'] != 2) ? 1 : 2,
            },
            where: 'id = ?',
            whereArgs: [listId],
          );

          setState(() {});
        }
      } catch (e) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Something went wrong, Please try again later.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_list',
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
                      final sharedWithCount = list['shared_with_count'];

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
                            onTap: () async {
                              final Database database = await _initDatabase();
                              int posixTime =
                                  DateTime.now().millisecondsSinceEpoch ~/ 1000;

                              if (connected) {
                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                        'https://robin.humilis.net/flutter/listapp/mylist.php'),
                                    body: {
                                      'userid': widget.userId,
                                      'listid': list['id'].toString(),
                                      'posixTime': posixTime.toString(),
                                    },
                                  );

                                  if (response.statusCode != 200) {
                                    print(
                                        'Somethign went wrong when updating last_opened with web api');
                                  }
                                } catch (e) {
                                  connected = false;
                                  setState(() {});
                                  throw e;
                                }
                              }

                              await database.update(
                                'lists',
                                {
                                  'last_opened': posixTime,
                                  'uploaded': (list['uploaded'] == 2)
                                      ? 2
                                      : (connected ? 0 : 1),
                                },
                                where: 'id = ?',
                                whereArgs: [list['id']],
                              );

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
