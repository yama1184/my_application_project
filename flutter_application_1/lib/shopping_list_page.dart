import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pantry_list_data.dart';

class ShoppingListPage extends StatefulWidget {
  final Map<String, List<dynamic>> shoppingList;
  final Function(String) onRemoveItem;
  final Function(String, double, String) onEditItem;
  final Function(Map<String, double> itemsToAdd) onItemsAdded;
  final Function(String item, String unit) onAddToShoppingList;
  final Function(String category, String newIngredient, String unit)
      addNewIngredientToCategory;
  final Map<String, List<String>> categoryIngredients;
  final List<String> stockList;
  final Function(String item) onRemoveFromStockList;
  final Function(String ingredient) getUnitForIngredient;

  const ShoppingListPage({
    super.key,
    required this.shoppingList,
    required this.onRemoveItem,
    required this.onEditItem,
    required this.onItemsAdded,
    required this.onAddToShoppingList,
    required this.addNewIngredientToCategory,
    required this.categoryIngredients,
    required this.stockList,
    required this.onRemoveFromStockList,
    required this.getUnitForIngredient,
  });

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final Set<String> _checkedItems = {};
  final List<String> _recentlyAddedItems = [];

  @override
  void initState() {
    super.initState();
    _loadRecentData();
  }

  Future<void> _loadRecentData() async {
    final prefs = await SharedPreferences.getInstance();
    final recentItems = prefs.getStringList('recentlyAddedItems') ?? [];
    setState(() {
      _recentlyAddedItems.addAll(recentItems);
    });
  }

  void _showAddItemDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String? selectedCategory = widget.categoryIngredients.keys.first;
    String? selectedUnit = '個';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('食材の追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: widget.categoryIngredients.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'カテゴリ'),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '食材名'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    items: ['g', '個', '本', 'ml', '合', '袋'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedUnit = newValue;
                      });
                    },
                    decoration: const InputDecoration(labelText: '単位'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        selectedCategory != null &&
                        selectedUnit != null) {
                      widget.onAddToShoppingList(
                          nameController.text, selectedUnit!);
                      widget.addNewIngredientToCategory(selectedCategory!,
                          nameController.text, selectedUnit!);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditQuantityDialog(BuildContext context, String item) {
    final double currentQuantity = widget.shoppingList[item]?[0] ?? 1.0;
    final String currentUnit = widget.shoppingList[item]?[1] ?? '個';
    final TextEditingController quantityController =
        TextEditingController(text: currentQuantity.toInt().toString());
    String? selectedUnit = currentUnit;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: '数量'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    items: ['g', '個', '本', 'ml', '合', '袋'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedUnit = newValue;
                      });
                    },
                    decoration: const InputDecoration(labelText: '単位'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    final newQuantity =
                        double.tryParse(quantityController.text)?.toDouble() ??
                            1.0;
                    widget.onEditItem(item, newQuantity, selectedUnit ?? '個');
                    Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStockListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ストックリスト'),
          content: SizedBox(
            width: double.maxFinite,
            child: widget.stockList.isEmpty
                ? const Center(child: Text('ストックリストは空です。'))
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: widget.stockList.map((item) {
                      return GestureDetector(
                        onTap: () {
                          final unit = widget.getUnitForIngredient(item);
                          widget.onAddToShoppingList(item, unit);
                          // Navigator.of(context).pop(); // この行を削除して連続選択を可能にする
                        },
                        child: Chip(
                          label: Text(
                            item,
                            style: const TextStyle(fontSize: 20),
                          ),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () {
                            _confirmRemoveFromStockList(context, item);
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveFromStockList(BuildContext context, String item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認'),
          content: Text('ストックリストから「$item」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  widget.onRemoveFromStockList(item);
                });
                Navigator.of(context).pop();
              },
              child: const Text('はい'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('いいえ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCheckedItems() {
    setState(() {
      for (var item in _checkedItems) {
        widget.onRemoveItem(item);
      }
      _checkedItems.clear();
    });
  }

  String _getCategoryForIngredient(String ingredient) {
    for (var category in widget.categoryIngredients.keys) {
      if (widget.categoryIngredients[category]!.contains(ingredient)) {
        return category;
      }
    }
    return 'その他';
  }

  @override
  Widget build(BuildContext context) {
    final List<String> uncheckedItems = [];
    final List<String> checkedItems = [];
    widget.shoppingList.keys.forEach((item) {
      if (_checkedItems.contains(item)) {
        checkedItems.add(item);
      } else {
        uncheckedItems.add(item);
      }
    });

    uncheckedItems.sort((a, b) {
      final categoryA = _getCategoryForIngredient(a);
      final categoryB = _getCategoryForIngredient(b);
      final categoryComparison = categoryA.compareTo(categoryB);
      if (categoryComparison != 0) {
        return categoryComparison;
      }
      return a.compareTo(b);
    });

    checkedItems.sort((a, b) {
      final categoryA = _getCategoryForIngredient(a);
      final categoryB = _getCategoryForIngredient(b);
      final categoryComparison = categoryA.compareTo(categoryB);
      if (categoryComparison != 0) {
        return categoryComparison;
      }
      return a.compareTo(b);
    });

    final sortedItems = [...uncheckedItems, ...checkedItems];

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showStockListDialog(context),
              icon: const Icon(Icons.inventory, size: 18),
              label: const Text('ストックを表示', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final quantity = widget.shoppingList[item]?[0] ?? 1.0;
                final unit = widget.shoppingList[item]?[1] ?? '個';
                final category = _getCategoryForIngredient(item);
                final isChecked = _checkedItems.contains(item);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    leading: Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _checkedItems.add(item);
                          } else {
                            _checkedItems.remove(item);
                          }
                        });
                      },
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            item,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isChecked ? Colors.grey : Colors.black,
                              decoration: null,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            category,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: isChecked
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            quantity.toStringAsFixed(
                                quantity.truncateToDouble() == quantity
                                    ? 0
                                    : 1),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14,
                              color: isChecked ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            unit,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14,
                              color: isChecked ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        widget.onRemoveItem(item);
                        setState(() {
                          _checkedItems.remove(item);
                        });
                      },
                    ),
                    onTap: () => _showEditQuantityDialog(context, item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _checkedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _deleteCheckedItems,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete_forever),
              label: const Text('まとめて削除'),
            )
          : null,
    );
  }
}
