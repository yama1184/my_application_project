// lib/shopping_list_data.dart
class ShoppingListItem {
  String ingredientName;
  double quantity;
  String unit;
  List<RecipeSource> sources;

  ShoppingListItem({
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.sources,
  });
}

class RecipeSource {
  String recipeName;
  int servings;

  RecipeSource({required this.recipeName, required this.servings});
}
