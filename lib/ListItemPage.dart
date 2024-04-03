import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ListItemsPage extends StatefulWidget {
  final String userId;
  final int listId;
  final String listName;

  ListItemsPage({required this.userId, required this.listId, required this.listName});

  @override
  _ListItemsPageState createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  TextEditingController _itemNameController = TextEditingController();
  FocusNode _itemNameFocusNode = FocusNode();

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNameFocusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
      body: {'userId': widget.userId, 'listId': widget.listId.toString()},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<void> _editItem(BuildContext context, int itemId, String itemName) async {
    TextEditingController _itemNameController = TextEditingController(text: itemName);
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
                // Send request to update item name
                final response = await http.post(
                  Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
                  body: {'userId': widget.userId, 'itemId': itemId.toString(), 'itemName': _itemNameController.text},
                );
                print('Response: ${response.body}');
                print('Response code: ${response.statusCode}');
                if (response.statusCode == 200) {
                  setState(() {});
                  print('Item name updated successfully');
                } else {
                  print('Failed to update item name');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateItemArchive(BuildContext context, int itemId, int archiveStatus) async {
    final response = await http.post(
      Uri.parse('https://robin.humilis.net/flutter/listapp/list_items.php'),
      body: {'userId': widget.userId, 'itemId': itemId.toString(), 'archiveStatus': archiveStatus.toString()},
    );
    print('Response: ${response.body}');
    print('Response code: ${response.statusCode}');
    if (response.statusCode == 200) {
      setState(() {});
      print('Item archive status updated successfully');
    } else {
      print('Failed to update item archive status');
    }
  }

  List<Widget> _buildSlidableActions(BuildContext context, Map<String, dynamic> item) {
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
    Future<void> _addItem(String itemName) async {
      try {
        final response = await http.post(
          Uri.parse('https://robin.humilis.net/flutter/listapp/add_item.php'),
          body: {'userId': widget.userId, 'listId': widget.listId.toString(), 'itemName': itemName},
        );
        print('Response: ${response.body}');
        if (response.statusCode == 200) {
          // Refresh the list after adding the new item
          setState(() {});
          _itemNameController.clear();
        } else {
          throw Exception('Failed to add item');
        }
      } catch (e) {
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
              // Automatically focus on the text input and open keyboard
              FocusScope.of(context).requestFocus(_itemNameFocusNode);
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Add New Item'),
                    content: TextField(
                      controller: _itemNameController,
                      focusNode: _itemNameFocusNode,
                      decoration: const InputDecoration(hintText: 'Enter Item Name'),
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
            // If the list has no items
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
                    title: Text('Swipe left or right to edit or delete'),
                    dense: true,
                  );
                } else {
                  final item = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                        tileColor: item['archive'] == 1 ? Colors.grey[150] : Colors.grey[300],
                        title: Text(
                          item['item_name'].toString(),
                          style: TextStyle(
                            decoration: item['archive'] == 1 ? TextDecoration.lineThrough : null,
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
