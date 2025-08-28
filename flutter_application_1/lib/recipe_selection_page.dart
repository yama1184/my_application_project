// lib/recipe_selection_page.dart
import 'package:flutter/material.dart';
import 'recipe_data.dart';
import 'pantry_list_data.dart';
import 'add_recipe_page.dart';
import 'package:reorderables/reorderables.dart';
import 'dart:io';

class RecipeSelectionPage extends StatefulWidget {
  final Function(Map<String, Map<String, dynamic>> itemsToAdd,
      String recipeName, int servings) onItemsAdded;
  final Map<String, List<PantryListData>> pantryList;
  final Function(Recipe recipe) onRecipeRegistered;
  final Function(Recipe recipe) onRecipeDeleted;
  final Function(Recipe originalRecipe, Recipe updatedRecipe) onRecipeEdited;
  final Function(int oldIndex, int newIndex) onReorder;
  final List<Recipe> cookableRecipes;
  final List<Recipe> missingRecipes;

  const RecipeSelectionPage({
    super.key,
    required this.onItemsAdded,
    required this.pantryList,
    required this.onRecipeRegistered,
    required this.onRecipeDeleted,
    required this.onRecipeEdited,
    required this.onReorder,
    required this.cookableRecipes,
    required this.missingRecipes,
  });

  @override
  State<RecipeSelectionPage> createState() => _RecipeSelectionPageState();
}

class _RecipeSelectionPageState extends State<RecipeSelectionPage> {
  final _scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  double _personCount = 2.0;

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToDetailPage(Recipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipePage(
          onRecipeRegistered: (newRecipe) {},
          initialRecipe: recipe,
          onRecipeEdited: widget.onRecipeEdited,
        ),
      ),
    );

    if (result == 'delete') {
      widget.onRecipeDeleted(recipe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cookableRecipeWidgets = widget.cookableRecipes
        .map((recipe) => _buildRecipeCard(recipe, true))
        .toList();
    final List<Widget> missingRecipeWidgets = widget.missingRecipes
        .map((recipe) => _buildRecipeCard(recipe, false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('レシピ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRecipePage(
                    onRecipeRegistered: widget.onRecipeRegistered,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: Text(
                    '作れるレシピ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: _currentPageIndex == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: Text(
                    '材料が足りないレシピ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: _currentPageIndex == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                _buildCookableRecipes(cookableRecipeWidgets),
                _buildMissingRecipes(missingRecipeWidgets),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookableRecipes(List<Widget> recipes) {
    if (recipes.isEmpty) {
      return const Center(child: Text('作れるレシピがありません。'));
    }
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ReorderableWrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: recipes,
          onReorder: widget.onReorder,
        ),
      ),
    );
  }

  Widget _buildMissingRecipes(List<Widget> recipes) {
    if (recipes.isEmpty) {
      return const Center(child: Text('材料が足りないレシピはありません。'));
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: recipes,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, bool isCookable) {
    return SizedBox(
      width: 150,
      child: GestureDetector(
        onTap: () => _navigateToDetailPage(recipe),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: recipe.imagePath.startsWith('assets/')
                    ? Image.asset(
                        recipe.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      )
                    : Image.file(
                        File(recipe.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  recipe.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isCookable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${recipe.missingIngredients?.length ?? 0}個の材料が不足',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (isCookable)
                ElevatedButton(
                  onPressed: () {
                    final Map<String, Map<String, dynamic>> itemsToAdd = {};
                    recipe.ingredients.forEach((ingredient, details) {
                      itemsToAdd[ingredient] = {
                        'quantity': details['quantity'] * _personCount,
                        'unit': details['unit'],
                      };
                    });
                    widget.onItemsAdded(
                        itemsToAdd, recipe.name, _personCount.round());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${recipe.name}の材料を買い物リストに追加しました')),
                    );
                  },
                  child: const Text('材料をリストに追加'),
                ),
              if (!isCookable)
                ElevatedButton(
                  onPressed: () {
                    final Map<String, Map<String, dynamic>> itemsToAdd = {};
                    recipe.ingredients.forEach((ingredient, details) {
                      if (recipe.missingIngredients != null &&
                          recipe.missingIngredients!.contains(ingredient)) {
                        itemsToAdd[ingredient] = {
                          'quantity': details['quantity'] * _personCount,
                          'unit': details['unit'],
                        };
                      }
                    });
                    widget.onItemsAdded(
                        itemsToAdd, recipe.name, _personCount.round());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${recipe.name}の不足材料を買い物リストに追加しました')),
                    );
                  },
                  child: const Text('不足材料を追加'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
