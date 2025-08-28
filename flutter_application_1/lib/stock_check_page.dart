// lib/stock_check_page.dart
import 'package:flutter/material.dart';
import 'pantry_list_data.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StockCheckPage extends StatefulWidget {
  final Map<String, List<String>> categoryIngredients;
  final Map<String, List<PantryListData>> pantryList;
  final Map<String, int> ingredientUsageCount;
  final Function() saveData;
  final Function(String category, String newIngredient)
      addNewIngredientToCategory;
  final Function(Map<String, double> itemsToAdd) onItemsAdded;
  final Map<String, List<String>> stockList;
  final Function(String category, String item) onAddToShoppingList;
  final Function(String category, String item)
      onRemoveStockItem; // onRemoveStockItemの引数を修正
  final Function(String category, PantryListData item)
      onAddStockItem; // 引数の型を修正

  const StockCheckPage({
    super.key,
    required this.categoryIngredients,
    required this.pantryList,
    required this.ingredientUsageCount,
    required this.saveData,
    required this.addNewIngredientToCategory,
    required this.onItemsAdded,
    required this.stockList,
    required this.onAddToShoppingList,
    required this.onRemoveStockItem,
    required this.onAddStockItem,
  });

  @override
  State<StockCheckPage> createState() => _StockCheckPageState();
}

class _StockCheckPageState extends State<StockCheckPage> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryIngredients.keys.first;
  }

  String _getCategoryForIngredient(String ingredient) {
    for (var category in widget.categoryIngredients.keys) {
      if (widget.categoryIngredients[category]!.contains(ingredient)) {
        return category;
      }
    }
    return 'その他';
  }

  void _addPantryItem(String name) {
    setState(() {
      final category = _getCategoryForIngredient(name);
      final newPantryItem = PantryListData(
        name: name,
        quantity: 1,
        unit: '個',
      );
      widget.onAddStockItem(category, newPantryItem);
      widget.saveData();
    });
  }

  void _showAddToCartDialog(BuildContext context, PantryListData item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${item.name}を買い物リストに追加'),
          content: const Text('在庫がなくなりましたか？買い物リストに追加しますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('いいえ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAddToShoppingList(
                  _getCategoryForIngredient(item.name),
                  item.name,
                );
                // --- 修正箇所 ---
                // onAddStockItemではなく、onRemoveStockItemを呼び出す
                widget.onRemoveStockItem(
                    _getCategoryForIngredient(item.name), item.name);
              },
              child: const Text('はい'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPantryItemDialog(BuildContext context, PantryListData item) {
    final TextEditingController quantityController =
        TextEditingController(text: item.quantity.toString());
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
                        const TextInputType.numberWithOptions(decimal: true),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    final newQuantity =
                        double.tryParse(quantityController.text) ??
                            item.quantity;
                    final newUnit = selectedUnit ?? item.unit;

                    // --- 修正箇所 ---
                    // onAddStockItemに更新されたPantryListDataオブジェクトを渡す
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

  @override
  Widget build(BuildContext context) {
    final allPantryItems =
        widget.pantryList.values.expand((list) => list).toList();
    final ingredientsInSelectedCategory =
        widget.categoryIngredients[_selectedCategory!] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('パントリー'),
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
                return GestureDetector(
                  onTap: () => _addPantryItem(ingredientName),
                  child: Card(
                    color: Colors.deepPurple[100],
                    child: Center(
                      child: Text(ingredientName),
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
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} ${item.unit}'),
                    onTap: () => _showEditPantryItemDialog(context, item),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => _showAddToCartDialog(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // --- 修正箇所 ---
                            // _removePantryItem()を直接呼び出すのではなく、onRemoveStockItemを呼び出す
                            widget.onRemoveStockItem(
                                _getCategoryForIngredient(item.name),
                                item.name);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
