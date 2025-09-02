// lib/stock_check_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'pantry_list_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StockCheckPage extends StatefulWidget {
  final Map<String, List<String>> categoryIngredients;
  final Map<String, List<PantryListData>> pantryList;
  final Map<String, int> ingredientUsageCount;
  final Function() saveData;
  final Function(String category, String newIngredient, String unit)
      addNewIngredientToCategory;
  final Function(Map<String, double> itemsToAdd) onItemsAdded;
  final Function(String item, String unit) onAddToShoppingList;
  final Function(String category, String item) onRemoveStockItem;
  final Function(String category, PantryListData item) onAddStockItem;
  final Function(String item) onAddToStockList;
  final Function(String oldCategory, String oldIngredient, String newCategory,
      String newIngredient, String newUnit) updateCategoryIngredient;
  final Function(String category, String ingredient) removeCategoryIngredient;

  const StockCheckPage({
    super.key,
    required this.categoryIngredients,
    required this.pantryList,
    required this.ingredientUsageCount,
    required this.saveData,
    required this.addNewIngredientToCategory,
    required this.onItemsAdded,
    required this.onAddToShoppingList,
    required this.onRemoveStockItem,
    required this.onAddStockItem,
    required this.onAddToStockList,
    required this.updateCategoryIngredient,
    required this.removeCategoryIngredient,
  });

  @override
  State<StockCheckPage> createState() => _StockCheckPageState();
}

class _StockCheckPageState extends State<StockCheckPage> {
  String? _selectedCategory;
  final Map<String, int> _ingredientUsageCount = {};
  final List<String> _recentlyAddedItems = [];

  final Set<String> _selectedItemsForDeletion = {};

  @override
  void initState() {
    super.initState();
    _loadRecentAndUsageData();
    if (widget.categoryIngredients.isNotEmpty) {
      _selectedCategory = widget.categoryIngredients.keys.first;
    } else {
      _selectedCategory = 'その他';
    }
  }

  Future<void> _loadRecentAndUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    final recentItems = prefs.getStringList('recentlyAddedItems') ?? [];
    final usageCountJson = prefs.getString('ingredientUsageCount');

    setState(() {
      _recentlyAddedItems.addAll(recentItems);
      if (usageCountJson != null) {
        _ingredientUsageCount
            .addAll(Map<String, int>.from(jsonDecode(usageCountJson) as Map));
      }
    });
  }

  Future<void> _saveRecentAndUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('recentlyAddedItems', _recentlyAddedItems);
    prefs.setString('ingredientUsageCount', jsonEncode(_ingredientUsageCount));
  }

  void _addPantryItem(
      String name, String category, double quantity, String unit) {
    setState(() {
      final newPantryItem = PantryListData(
        name: name,
        quantity: quantity,
        unit: unit,
      );
      widget.onAddStockItem(category, newPantryItem);
      _recentlyAddedItems.remove(name);
      _recentlyAddedItems.insert(0, name);
      if (_recentlyAddedItems.length > 10) {
        _recentlyAddedItems.removeLast();
      }
    });
    _saveRecentAndUsageData();
    widget.saveData();
  }

  void _showAddToCartDialog(BuildContext context, PantryListData item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${item.name}の在庫がなくなりましたか？'),
          content: const Text('買い物リストに追加しますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAddToShoppingList(item.name, item.unit);
                widget.onRemoveStockItem(
                    _getCategoryForIngredient(item.name), item.name);
              },
              child: const Text('はい'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAddToStockList(item.name);
              },
              child: const Text('ストックに追加'),
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

  void _showEditPantryItemDialog(BuildContext context, PantryListData item) {
    final TextEditingController quantityController =
        TextEditingController(text: item.quantity.toInt().toString());
    String? selectedUnit = item.unit;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item.name),
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
                        double.tryParse(quantityController.text) ??
                            item.quantity;
                    final newUnit = selectedUnit ?? item.unit;
                    widget.onAddStockItem(
                      _getCategoryForIngredient(item.name),
                      PantryListData(
                          name: item.name,
                          quantity: newQuantity,
                          unit: newUnit),
                    );
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

  void _showAddItemDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String? selectedCategory = widget.categoryIngredients.keys.isNotEmpty
        ? widget.categoryIngredients.keys.first
        : 'その他';
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
                      _addPantryItem(nameController.text, selectedCategory!,
                          1.0, selectedUnit!);
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

  String _getCategoryForIngredient(String ingredient) {
    for (var category in widget.categoryIngredients.keys) {
      if (widget.categoryIngredients[category]!.contains(ingredient)) {
        return category;
      }
    }
    return 'その他';
  }

  void _showEditCategoryIngredientDialog(
      String oldCategory, String oldIngredient) {
    final TextEditingController nameController =
        TextEditingController(text: oldIngredient);
    String? selectedCategory = oldCategory;
    String? selectedUnit = _getUnitForIngredient(oldIngredient);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('「$oldIngredient」を編集'),
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
                    widget.removeCategoryIngredient(oldCategory, oldIngredient);
                    Navigator.of(context).pop();
                  },
                  child: const Text('削除', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        selectedCategory != null &&
                        selectedUnit != null) {
                      widget.updateCategoryIngredient(
                          oldCategory,
                          oldIngredient,
                          selectedCategory!,
                          nameController.text,
                          selectedUnit!);
                      Navigator.of(context).pop();
                    }
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

  String _getUnitForIngredient(String ingredient) {
    final allPantryItems =
        widget.pantryList.values.expand((list) => list).toList();
    final item = allPantryItems.firstWhere(
        (pantryItem) => pantryItem.name == ingredient,
        orElse: () => PantryListData(name: '', quantity: 0, unit: '個'));
    return item.unit;
  }

  void _confirmDeleteSelectedItems() {
    if (_selectedItemsForDeletion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除するアイテムを選択してください。')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アイテムを削除しますか？'),
          content: Text('${_selectedItemsForDeletion.length}個のアイテムを削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedItems();
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedItems() {
    setState(() {
      for (var item in _selectedItemsForDeletion) {
        widget.onRemoveStockItem(_getCategoryForIngredient(item), item);
      }
      _selectedItemsForDeletion.clear();
    });
    widget.saveData();
  }

  @override
  Widget build(BuildContext context) {
    final allPantryItems =
        widget.pantryList.values.expand((list) => list).toList();
    allPantryItems.sort((a, b) {
      final categoryA = _getCategoryForIngredient(a.name);
      final categoryB = _getCategoryForIngredient(b.name);
      return categoryA.compareTo(categoryB);
    });

    final ingredientsInSelectedCategory =
        (widget.categoryIngredients[_selectedCategory ?? ''] ?? []).toList();
    ingredientsInSelectedCategory.sort((a, b) {
      final aIndex = _recentlyAddedItems.indexOf(a);
      final bIndex = _recentlyAddedItems.indexOf(b);

      if (aIndex != -1 && bIndex == -1) return -1;
      if (aIndex == -1 && bIndex != -1) return 1;
      if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);

      return a.compareTo(b);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('パントリー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: widget.categoryIngredients.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'カテゴリ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: MasonryGridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              itemCount: ingredientsInSelectedCategory.length,
              itemBuilder: (context, index) {
                final ingredientName = ingredientsInSelectedCategory[index];
                final category = _selectedCategory!;
                return Card(
                  elevation: 1.0,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  color: Colors.deepPurple[100],
                  child: InkWell(
                    onTap: () {
                      final unit = _getUnitForIngredient(ingredientName);
                      _addPantryItem(ingredientName, category, 1.0, unit);
                    },
                    borderRadius: BorderRadius.circular(4.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(ingredientName,
                                textAlign: TextAlign.center),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () {
                            _showEditCategoryIngredientDialog(
                                category, ingredientName);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: allPantryItems.length,
              itemBuilder: (context, index) {
                final item = allPantryItems[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    leading: Checkbox(
                      value: _selectedItemsForDeletion.contains(item.name),
                      onChanged: (bool? isChecked) {
                        setState(() {
                          if (isChecked == true) {
                            _selectedItemsForDeletion.add(item.name);
                          } else {
                            _selectedItemsForDeletion.remove(item.name);
                          }
                        });
                      },
                    ),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _getCategoryForIngredient(item.name),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.quantity.toInt().toString(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.unit,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          onPressed: () => _showAddToCartDialog(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            widget.onRemoveStockItem(
                                _getCategoryForIngredient(item.name),
                                item.name);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _showEditPantryItemDialog(context, item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedItemsForDeletion.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: _confirmDeleteSelectedItems,
              child: const Icon(Icons.delete_sweep),
            )
          : null,
    );
  }
}
