import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pantry_list_data.dart';
import 'shopping_list_page.dart';
import 'stock_check_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  Map<String, List<String>> _categoryIngredients = {};
  Map<String, List<PantryListData>> _pantryList = {};
  Map<String, List<dynamic>> _shoppingList = {};
  Map<String, int> _ingredientUsageCount = {};
  Map<String, int> _pantryItemCounts = {};
  List<String> _stockList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 🔴 修正: カテゴリを強制的にリセットする
    //await prefs.remove('categoryIngredients');

    final String? categoriesJson = prefs.getString('categoryIngredients');
    if (categoriesJson == null || categoriesJson == '{}') {
      _categoryIngredients = {
        '主食': ['米', 'パン', '麺'],
        '肉類': [
          '鶏肉',
          '鶏もも肉',
          '鶏むね肉',
          '豚肉',
          '牛肉',
          '牛バラ肉',
          '牛もも肉',
          '豚バラ肉',
          '豚もも肉',
          'ひき肉'
        ],
        '魚類': ['鮭', 'マグロ', 'サンマ', 'サバ', 'ブリ', 'アジ'],
        '野菜': [
          'キャベツ',
          '玉ねぎ',
          '人参',
          'じゃがいも',
          'トマト',
          'ピーマン',
          '白菜',
          'レタス',
          'ねぎ',
          'ほうれん草',
          'なす'
        ],
        '調味料': ['塩', '砂糖', 'しょう油', '味噌', '油', '酢', 'マヨネーズ', 'ケチャップ', 'だし'],
        '乳製品・卵': ['牛乳', '卵', 'チーズ', 'ヨーグルト', 'バター'],
        'その他': ['食器洗剤', 'トイレットぺーパー', '洗濯洗剤', 'シャンプー', 'ボディソープ', 'ごみ袋'],
      };
      await prefs.setString(
          'categoryIngredients', jsonEncode(_categoryIngredients));
    } else {
      _categoryIngredients = _decodeCategoryIngredients(categoriesJson);
    }

    setState(() {
      _pantryList = _decodePantryList(prefs.getString('pantryList') ?? '{}');
      _shoppingList =
          _decodeShoppingList(prefs.getString('shoppingList') ?? '{}');
      _ingredientUsageCount = _decodeIngredientUsage(
          prefs.getString('ingredientUsageCount') ?? '{}');
      _pantryItemCounts =
          _decodePantryItemCounts(prefs.getString('pantryItemCounts') ?? '{}');

      final stockListFromPrefs = prefs.get('stockList');
      if (stockListFromPrefs is List<dynamic>) {
        _stockList = List<String>.from(stockListFromPrefs);
      } else {
        _stockList = [];
        prefs.remove('stockList');
      }

      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('categoryIngredients', jsonEncode(_categoryIngredients));
    prefs.setString('pantryList', jsonEncode(_encodePantryList()));
    prefs.setString('shoppingList', jsonEncode(_shoppingList));
    prefs.setString('ingredientUsageCount', jsonEncode(_ingredientUsageCount));
    prefs.setString('pantryItemCounts', jsonEncode(_pantryItemCounts));
    prefs.setStringList('stockList', _stockList);
  }

  Map<String, List<String>> _decodeCategoryIngredients(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded
        .map((key, value) => MapEntry(key, List<String>.from(value as List)));
  }

  Map<String, dynamic> _encodePantryList() {
    return _pantryList.map((category, items) => MapEntry(
        category,
        items
            .map((item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                  'unit': item.unit,
                })
            .toList()));
  }

  Map<String, List<PantryListData>> _decodePantryList(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
        key,
        (value as List)
            .map((item) => PantryListData(
                  name: item['name'],
                  quantity: item['quantity']?.toDouble() ?? 0.0,
                  unit: item['unit'] ?? '個',
                ))
            .toList()));
  }

  Map<String, List<dynamic>> _decodeShoppingList(String jsonString) {
    if (jsonString.isEmpty || jsonString == '{}') return {};
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) {
      if (value is List) {
        return MapEntry(key, List<dynamic>.from(value));
      } else {
        return MapEntry(key, [value?.toDouble() ?? 1.0, '個']);
      }
    });
  }

  Map<String, int> _decodeIngredientUsage(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  Map<String, int> _decodePantryItemCounts(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addStockItem(String category, PantryListData item) {
    setState(() {
      if (!_pantryList.containsKey(category)) {
        _pantryList[category] = [];
      }
      final existingItemIndex =
          _pantryList[category]!.indexWhere((i) => i.name == item.name);
      if (existingItemIndex != -1) {
        _pantryList[category]![existingItemIndex] = item;
      } else {
        _pantryList[category]!.add(item);
      }
      _pantryList[category]!.sort((a, b) => a.name.compareTo(b.name));
      _saveData();
    });
  }

  void _removeStockItem(String category, String item) {
    setState(() {
      _pantryList[category]?.removeWhere((i) => i.name == item);
      if (_pantryList[category]?.isEmpty ?? false) {
        _pantryList.remove(category);
      }
      _saveData();
    });
  }

  void _addToShoppingList(String item, String unit) {
    setState(() {
      _shoppingList[item] = [1.0, unit];
      _saveData();
    });
  }

  void _removeItemFromShoppingList(String item) {
    setState(() {
      _shoppingList.remove(item);
      _saveData();
    });
  }

  void _editShoppingItemQuantity(
      String item, double newQuantity, String newUnit) {
    setState(() {
      _shoppingList[item] = [newQuantity, newUnit];
      if (newQuantity <= 0) {
        _shoppingList.remove(item);
      }
      _saveData();
    });
  }

  void _addToStockList(String item) {
    setState(() {
      if (!_stockList.contains(item)) {
        _stockList.add(item);
        _saveData();
      }
    });
  }

  void _removeFromStockList(String item) {
    setState(() {
      _stockList.remove(item);
      _saveData();
    });
  }

  void _addNewIngredientToCategory(
      String category, String newIngredient, String unit) {
    setState(() {
      if (!_categoryIngredients.containsKey(category)) {
        _categoryIngredients[category] = [];
      }
      if (!_categoryIngredients[category]!.contains(newIngredient)) {
        _categoryIngredients[category]!.add(newIngredient);
        final newPantryItem =
            PantryListData(name: newIngredient, quantity: 0, unit: unit);
        if (!_pantryList.containsKey(category)) {
          _pantryList[category] = [];
        }
        if (!_pantryList[category]!.any((item) => item.name == newIngredient)) {
          _pantryList[category]!.add(newPantryItem);
        }
        _saveData();
      }
    });
  }

  void _updateCategoryIngredient(String oldCategory, String oldIngredient,
      String newCategory, String newIngredient, String newUnit) {
    setState(() {
      _categoryIngredients[oldCategory]?.remove(oldIngredient);
      _pantryList[oldCategory]
          ?.removeWhere((item) => item.name == oldIngredient);
      if (_pantryList[oldCategory]?.isEmpty ?? false) {
        _pantryList.remove(oldCategory);
      }

      if (!_categoryIngredients.containsKey(newCategory)) {
        _categoryIngredients[newCategory] = [];
      }
      if (!_categoryIngredients[newCategory]!.contains(newIngredient)) {
        _categoryIngredients[newCategory]!.add(newIngredient);
        _categoryIngredients[newCategory]!.sort();
      }

      if (!_pantryList.containsKey(newCategory)) {
        _pantryList[newCategory] = [];
      }
      final newPantryItem =
          PantryListData(name: newIngredient, quantity: 0, unit: newUnit);
      if (!_pantryList[newCategory]!
          .any((item) => item.name == newIngredient)) {
        _pantryList[newCategory]!.add(newPantryItem);
      }

      _saveData();
    });
  }

  void _removeCategoryIngredient(String category, String ingredient) {
    setState(() {
      _categoryIngredients[category]?.remove(ingredient);
      _pantryList[category]?.removeWhere((item) => item.name == ingredient);
      if (_pantryList[category]?.isEmpty ?? false) {
        _pantryList.remove(category);
      }
      _saveData();
    });
  }

  void _addItemsToShoppingList(Map<String, double> itemsToAdd) {
    setState(() {
      itemsToAdd.forEach((item, quantity) {
        _shoppingList.putIfAbsent(item, () => [quantity, '個']);
      });
      _saveData();
    });
  }

  String _getUnitForIngredient(String ingredient) {
    for (var categoryList in _pantryList.values) {
      for (var item in categoryList) {
        if (item.name == ingredient) {
          return item.unit;
        }
      }
    }
    return '個';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Widget> _widgetOptions = <Widget>[
      StockCheckPage(
        categoryIngredients: _categoryIngredients,
        pantryList: _pantryList,
        ingredientUsageCount: _ingredientUsageCount,
        saveData: _saveData,
        addNewIngredientToCategory: _addNewIngredientToCategory,
        onItemsAdded: _addItemsToShoppingList,
        onAddToShoppingList: _addToShoppingList,
        onRemoveStockItem: _removeStockItem,
        onAddStockItem: _addStockItem,
        onAddToStockList: _addToStockList,
        updateCategoryIngredient: _updateCategoryIngredient,
        removeCategoryIngredient: _removeCategoryIngredient,
        stockList: _stockList,
      ),
      ShoppingListPage(
        shoppingList: _shoppingList,
        onRemoveItem: _removeItemFromShoppingList,
        onEditItem: _editShoppingItemQuantity,
        addNewIngredientToCategory: _addNewIngredientToCategory,
        onItemsAdded: _addItemsToShoppingList,
        onAddToShoppingList: _addToShoppingList,
        categoryIngredients: _categoryIngredients,
        stockList: _stockList,
        onRemoveFromStockList: _removeFromStockList,
        getUnitForIngredient: _getUnitForIngredient,
      ),
    ];

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: 'パントリー',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: '買い物リスト',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
