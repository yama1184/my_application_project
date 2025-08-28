// lib/shopping_list_page.dart
import 'package:flutter/material.dart';
import 'shopping_list_data.dart';
import 'pantry_list_data.dart';

class ShoppingListPage extends StatefulWidget {
  final Map<String, ShoppingListItem> shoppingList;
  final Function(String itemName) onItemChecked;
  final Function(List<String> itemsToDelete) onItemsBulkDeleted;
  final Map<String, List<String>> stockList;
  final Function(String category, String item) onAddToShoppingList;
  final Function(String category, PantryListData item)
      onAddStockItem; // 引数の型を修正
  final Function(String category, String item) onRemoveStockItem;

  const ShoppingListPage({
    super.key,
    required this.shoppingList,
    required this.onItemChecked,
    required this.onItemsBulkDeleted,
    required this.stockList,
    required this.onAddToShoppingList,
    required this.onAddStockItem,
    required this.onRemoveStockItem,
  });

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final Set<String> _selectedItems = {};
  String? _selectedStockCategory;
  final TextEditingController _stockItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.stockList.isNotEmpty) {
      _selectedStockCategory = widget.stockList.keys.first;
    }
  }

  void _toggleSelection(String itemName) {
    setState(() {
      if (_selectedItems.contains(itemName)) {
        _selectedItems.remove(itemName);
      } else {
        _selectedItems.add(itemName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shoppingItems = widget.shoppingList.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                widget.onItemsBulkDeleted(_selectedItems.toList());
                setState(() {
                  _selectedItems.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStockSection(),
          Expanded(
            child: ListView.builder(
              itemCount: shoppingItems.length,
              itemBuilder: (context, index) {
                final item = shoppingItems[index];
                final isSelected = _selectedItems.contains(item.ingredientName);
                return ListTile(
                  title: Text(item.ingredientName),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleSelection(item.ingredientName);
                    },
                  ),
                  trailing: Text(
                    item.sources.map((s) => s.recipeName).join(', '),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ストックリスト',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStockCategory,
            items: widget.stockList.keys.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedStockCategory = newValue;
              });
            },
            decoration: const InputDecoration(labelText: 'カテゴリ'),
          ),
          const SizedBox(height: 8),
          if (_selectedStockCategory != null)
            Wrap(
              spacing: 8.0,
              children: widget.stockList[_selectedStockCategory!]!
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      onDeleted: () => widget.onRemoveStockItem(
                          _selectedStockCategory!, item),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockItemController,
                  decoration: const InputDecoration(labelText: '新しいストックアイテム'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_stockItemController.text.isNotEmpty &&
                      _selectedStockCategory != null) {
                    // --- 修正箇所 ---
                    // onAddStockItemにPantryListDataオブジェクトを渡す
                    widget.onAddStockItem(
                      _selectedStockCategory!,
                      PantryListData(
                          name: _stockItemController.text,
                          quantity: 1.0,
                          unit: '個'),
                    );
                    _stockItemController.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
