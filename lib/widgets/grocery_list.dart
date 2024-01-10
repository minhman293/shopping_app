import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shopping_app/data/categories.dart';

import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryList = [];
  var _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  _loadItem() async {
    final url = Uri.https(
      'flutter-course-a9ee2-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _errorMsg = "There is an error!";
      });
    }

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> dataFromFirebase = json.decode(response.body);
    final List<GroceryItem> tmpGroceryList = [];
    for (final item in dataFromFirebase.entries) {
      final category = categories.entries
          .firstWhere((element) => element.value.name == item.value['category'])
          .value;
      tmpGroceryList.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryList = tmpGroceryList;
      _isLoading = false;
    });
  }

  _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryList.add(newItem);
    });
  }

  _removeItem(GroceryItem item) {
    final url = Uri.https(
      'flutter-course-a9ee2-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    http.delete(url);

    setState(() {
      _groceryList.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen = const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'There is no grocery available now.',
            style: TextStyle(fontSize: 20),
          )
        ],
      ),
    );

    if (_isLoading) {
      currentScreen = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryList.isNotEmpty) {
      currentScreen = ListView.builder(
        itemCount: _groceryList.length,
        itemBuilder: ((context, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(_groceryList[index]);
              },
              key: ValueKey(_groceryList[index].id),
              child: ListTile(
                title: Text(_groceryList[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryList[index].category.color,
                ),
                trailing: Text(_groceryList[index].quantity.toString()),
              ),
            )),
      );
    }

    if (_errorMsg != null) {
      currentScreen = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMsg!,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: currentScreen,
    );
  }
}
