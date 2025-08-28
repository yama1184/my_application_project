// lib/main.dart
import 'package:flutter/material.dart';
import 'stock_check_page.dart';
import 'shopping_list_page.dart';
import 'recipe_data.dart';
import 'pantry_list_data.dart';
import 'recipe_selection_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'shopping_list_data.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final Map<String, List<PantryListData>> _pantryList = {
    '主食': [PantryListData(name: '米', quantity: 1, unit: 'g')],
    '肉': [PantryListData(name: '豚肉', quantity: 300, unit: 'g')],
    '野菜': [
      PantryListData(name: 'じゃがいも', quantity: 2, unit: '個'),
      PantryListData(name: '玉ねぎ', quantity: 1, unit: '個')
    ],
  };
  final Map<String, List<String>> _categoryIngredients = {
    '主食': ['米', 'パスタ', 'パン'],
    '肉': ['豚肉', '鶏肉', '牛肉'],
    '野菜': ['じゃがいも', '人参', '玉ねぎ', 'キャベツ'],
    '調味料': ['醤油', 'みりん', '砂糖', '塩', 'こしょう', '酒'],
    '乳製品・卵': ['牛乳', 'チーズ', 'バター', '卵'],
    'その他': ['小麦粉', '片栗粉'],
  };
  final Map<String, ShoppingListItem> _shoppingList = {};
  final Map<String, int> _ingredientUsageCount = {};
  Recipe? _selectedRecipe;
  final Map<String, List<String>> _stockList = {
    '調味料': ['醤油', 'みりん', '砂糖', '塩', 'こしょう'],
    '日用品': ['トイレットペーパー', '洗剤'],
    'その他': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> pantryJson = _pantryList.map(
        (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
    await prefs.setString('pantryList', jsonEncode(pantryJson));

    final Map<String, dynamic> shoppingJson =
        _shoppingList.map((key, value) => MapEntry(key, {
              'ingredientName': value.ingredientName,
              'quantity': value.quantity,
              'unit': value.unit,
              'sources': value.sources
                  .map((source) => {
                        'recipeName': source.recipeName,
                        'servings': source.servings,
                      })
                  .toList(),
            }));
    await prefs.setString('shoppingList', jsonEncode(shoppingJson));

    await prefs.setString(
        'categoryIngredients', jsonEncode(_categoryIngredients));

    final List<Map<String, dynamic>> recipesJson = recipes
        .map((e) => {
              'name': e.name,
              'imagePath': e.imagePath,
              'ingredients': e.ingredients,
              'instructions': e.instructions,
            })
        .toList();
    await prefs.setString('recipes', jsonEncode(recipesJson));

    await prefs.setString('stockList', jsonEncode(_stockList));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final String? pantryJsonString = prefs.getString('pantryList');
    if (pantryJsonString != null) {
      final Map<String, dynamic> pantryJson = jsonDecode(pantryJsonString);
      setState(() {
        _pantryList.clear();
        pantryJson.forEach((key, value) {
          _pantryList[key] =
              (value as List).map((e) => PantryListData.fromJson(e)).toList();
        });
      });
    }

    final String? shoppingJsonString = prefs.getString('shoppingList');
    if (shoppingJsonString != null) {
      final Map<String, dynamic> shoppingJson = jsonDecode(shoppingJsonString);
      setState(() {
        _shoppingList.clear();
        shoppingJson.forEach((key, value) {
          final sources = (value['sources'] as List)
              .map(
                (sourceJson) => RecipeSource(
                  recipeName: sourceJson['recipeName'],
                  servings: sourceJson['servings'],
                ),
              )
              .toList();
          _shoppingList[key] = ShoppingListItem(
            ingredientName: value['ingredientName'],
            quantity: value['quantity'],
            unit: value['unit'],
            sources: sources,
          );
        });
      });
    }

    final String? categoryJsonString = prefs.getString('categoryIngredients');
    if (categoryJsonString != null) {
      final Map<String, dynamic> categoryJson = jsonDecode(categoryJsonString);
      setState(() {
        _categoryIngredients.clear();
        categoryJson.forEach((key, value) {
          _categoryIngredients[key] =
              (value as List).map((e) => e.toString()).toList();
        });
      });
    }

    final String? recipesJsonString = prefs.getString('recipes');
    if (recipesJsonString != null) {
      final List<dynamic> recipesJson = jsonDecode(recipesJsonString);
      setState(() {
        recipes.clear();
        recipesJson.forEach((json) {
          recipes.add(Recipe(
            name: json['name'],
            imagePath: json['imagePath'],
            ingredients: (json['ingredients'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, value as Map<String, dynamic>),
            ),
            instructions: (json['instructions'] as List)
                .map((e) => e.toString())
                .toList(),
          ));
        });
      });
    }

    final String? stockListJsonString = prefs.getString('stockList');
    if (stockListJsonString != null) {
      final Map<String, dynamic> stockListJson =
          jsonDecode(stockListJsonString);
      setState(() {
        _stockList.clear();
        stockListJson.forEach((key, value) {
          _stockList[key] = (value as List).map((e) => e.toString()).toList();
        });
      });
    }
  }

  void _addNewIngredientToCategory(String category, String newIngredient) {
    if (!_categoryIngredients.containsKey(category)) {
      _categoryIngredients[category] = [];
    }
    if (!_categoryIngredients[category]!.contains(newIngredient)) {
      _categoryIngredients[category]!.add(newIngredient);
    }
    _saveData();
  }

  void _onItemsAdded(Map<String, Map<String, dynamic>> itemsToAdd,
      String recipeName, int servings) {
    setState(() {
      itemsToAdd.forEach((ingredient, itemData) {
        final double quantity = itemData['quantity'] as double;
        final String unit = itemData['unit'] as String;

        final newSource =
            RecipeSource(recipeName: recipeName, servings: servings);

        if (_shoppingList.containsKey(ingredient)) {
          _shoppingList[ingredient]!.quantity += quantity;
          final existingSources = _shoppingList[ingredient]!.sources;
          final isSourceExists = existingSources.any((source) =>
              source.recipeName == recipeName && source.servings == servings);
          if (!isSourceExists) {
            existingSources.add(newSource);
          }
        } else {
          _shoppingList[ingredient] = ShoppingListItem(
            ingredientName: ingredient,
            quantity: quantity,
            unit: unit,
            sources: [newSource],
          );
        }
      });
    });
    _saveData();
  }

  void _onStockItemAddedToShoppingList(String category, String item) {
    setState(() {
      if (!_shoppingList.containsKey(item)) {
        _shoppingList[item] = ShoppingListItem(
          ingredientName: item,
          quantity: 1,
          unit: '',
          sources: [RecipeSource(recipeName: 'ストック', servings: 0)],
        );
      }
    });
    _saveData();
  }

  // --- 修正箇所 ---
  // onAddStockItemの引数をPantryListDataに変更
  void _onAddStockItem(String category, PantryListData item) {
    setState(() {
      if (!_pantryList.containsKey(category)) {
        _pantryList[category] = [];
      }
      final existingItem = _pantryList[category]!.firstWhere(
        (pantryItem) => pantryItem.name == item.name,
        orElse: () => PantryListData(name: '', quantity: 0, unit: ''),
      );

      if (existingItem.name.isNotEmpty) {
        existingItem.quantity = item.quantity;
        existingItem.unit = item.unit;
      } else {
        _pantryList[category]!.add(item);
      }
    });
    _saveData();
  }

  // onRemoveStockItemの引数をPantryListDataに変更
  void _onRemoveStockItem(String category, String item) {
    setState(() {
      if (_pantryList.containsKey(category)) {
        _pantryList[category]!
            .removeWhere((pantryItem) => pantryItem.name == item);
      }
      if (_stockList.containsKey(category)) {
        _stockList[category]!.remove(item);
      }
    });
    _saveData();
  }
  // ----------------

  void _onItemChecked(String itemName) {
    setState(() {
      _shoppingList.remove(itemName);
    });
    _saveData();
  }

  void _onItemsBulkDeleted(List<String> itemsToDelete) {
    setState(() {
      for (var item in itemsToDelete) {
        _shoppingList.remove(item);
      }
    });
    _saveData();
  }

  void _addRecipe(Recipe recipe) {
    setState(() {
      recipes.add(recipe);
    });
    _saveData();
  }

  void _deleteRecipe(Recipe recipe) {
    setState(() {
      recipes.remove(recipe);
    });
    _saveData();
    if (!recipe.imagePath.startsWith('assets/')) {
      final file = File(recipe.imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  void _onRecipeEdited(Recipe originalRecipe, Recipe updatedRecipe) {
    setState(() {
      final index = recipes.indexOf(originalRecipe);
      if (index != -1) {
        recipes[index] = updatedRecipe;
      }
    });
    _saveData();

    if (!originalRecipe.imagePath.startsWith('assets/') &&
        originalRecipe.imagePath != updatedRecipe.imagePath) {
      final file = File(originalRecipe.imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  void _reorderRecipes(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Recipe item = recipes.removeAt(oldIndex);
      recipes.insert(newIndex, item);
    });
    _saveData();
  }

  List<List<Recipe>> _classifyRecipesByPantry() {
    final List<String> availableIngredients = _pantryList.values
        .expand((items) => items.map((item) => item.name))
        .toList();

    final List<Recipe> cookableRecipes = [];
    final List<Recipe> missingIngredientsRecipes = [];

    for (var recipe in recipes) {
      final List<String> missing = [];
      for (var ingredient in recipe.ingredients.keys) {
        if (!availableIngredients.contains(ingredient)) {
          missing.add(ingredient);
        }
      }
      if (missing.isEmpty) {
        cookableRecipes.add(recipe);
      } else {
        recipe.missingIngredients = missing;
        missingIngredientsRecipes.add(recipe);
      }
    }

    return [cookableRecipes, missingIngredientsRecipes];
  }

  @override
  Widget build(BuildContext context) {
    final classifiedRecipes = _classifyRecipesByPantry();
    final cookableRecipes = classifiedRecipes[0];
    final missingRecipes = classifiedRecipes[1];

    return MaterialApp(
      title: 'パントリー管理アプリ',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // パントリー画面
            StockCheckPage(
              pantryList: _pantryList,
              ingredientUsageCount: _ingredientUsageCount,
              saveData: _saveData,
              onItemsAdded: (itemsToAdd) {
                itemsToAdd.forEach((key, value) {
                  _onItemsAdded(
                    {
                      key: {'quantity': value, 'unit': ''}
                    },
                    'ストック補充',
                    0,
                  );
                });
              },
              categoryIngredients: _categoryIngredients,
              onAddToShoppingList: _onStockItemAddedToShoppingList,
              stockList: _stockList,
              onRemoveStockItem: _onRemoveStockItem,
              onAddStockItem: _onAddStockItem,
              addNewIngredientToCategory: _addNewIngredientToCategory,
            ),
            // 買い物リスト画面
            ShoppingListPage(
              shoppingList: _shoppingList,
              onItemChecked: _onItemChecked,
              onItemsBulkDeleted: _onItemsBulkDeleted,
              stockList: _stockList,
              onAddToShoppingList: _onStockItemAddedToShoppingList,
              onAddStockItem: _onAddStockItem,
              onRemoveStockItem: _onRemoveStockItem,
            ),
            // レシピ画面
            RecipeSelectionPage(
              onItemsAdded: _onItemsAdded,
              pantryList: _pantryList,
              onRecipeRegistered: _addRecipe,
              onRecipeDeleted: _deleteRecipe,
              onRecipeEdited: _onRecipeEdited,
              onReorder: _reorderRecipes,
              cookableRecipes: cookableRecipes,
              missingRecipes: missingRecipes,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'パントリー'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: '買い物リスト',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'レシピ'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
