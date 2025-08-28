// lib/recipe_data.dart
class Recipe {
  String name;
  String imagePath;
  Map<String, Map<String, dynamic>> ingredients;
  List<String> instructions;
  List<String>? missingIngredients; // この行が重要です。

  Recipe({
    required this.name,
    required this.imagePath,
    required this.ingredients,
    required this.instructions,
    this.missingIngredients,
  });
}

List<Recipe> recipes = [
  Recipe(
    name: '豚の生姜焼き',
    imagePath: 'assets/pork_ginger.jpg',
    ingredients: {
      '豚肉': {'quantity': 200.0, 'unit': 'g'},
      '玉ねぎ': {'quantity': 1.0, 'unit': '個'},
      '醤油': {'quantity': 2.0, 'unit': '大さじ'},
      'みりん': {'quantity': 2.0, 'unit': '大さじ'},
      '酒': {'quantity': 1.0, 'unit': '大さじ'},
      '砂糖': {'quantity': 1.0, 'unit': '小さじ'},
      '生姜': {'quantity': 1.0, 'unit': 'かけ'},
    },
    instructions: [
      '豚肉に生姜、醤油、みりん、酒、砂糖を混ぜたタレを揉み込む。',
      '玉ねぎを薄切りにする。',
      'フライパンに油をひき、玉ねぎを炒める。',
      '玉ねぎがしんなりしたら豚肉を加えて炒める。',
      '肉に火が通ったら完成。',
    ],
  ),
  Recipe(
    name: '鶏の唐揚げ',
    imagePath: 'assets/fried_chicken.jpg',
    ingredients: {
      '鶏肉': {'quantity': 300.0, 'unit': 'g'},
      '醤油': {'quantity': 2.0, 'unit': '大さじ'},
      '酒': {'quantity': 1.0, 'unit': '大さじ'},
      '生姜': {'quantity': 1.0, 'unit': 'かけ'},
      'にんにく': {'quantity': 1.0, 'unit': 'かけ'},
      '片栗粉': {'quantity': 3.0, 'unit': '大さじ'},
    },
    instructions: [
      '鶏肉を一口大に切る。',
      '醤油、酒、生姜、にんにくを混ぜたタレに鶏肉を30分漬け込む。',
      '鶏肉に片栗粉をまぶす。',
      '170℃の油で揚げる。',
    ],
  ),
  Recipe(
    name: 'カレーライス',
    imagePath: 'assets/curry_rice.jpg',
    ingredients: {
      '米': {'quantity': 2.0, 'unit': '合'},
      '牛肉': {'quantity': 200.0, 'unit': 'g'},
      '玉ねぎ': {'quantity': 1.0, 'unit': '個'},
      '人参': {'quantity': 1.0, 'unit': '本'},
      'じゃがいも': {'quantity': 1.0, 'unit': '個'},
      'カレールー': {'quantity': 1.0, 'unit': '箱'},
    },
    instructions: [
      '米を炊く。',
      '野菜と肉を一口大に切る。',
      '鍋で野菜と肉を炒める。',
      '水を加えて煮込む。',
      '火を止めてカレールーを溶かし、再び弱火で煮込む。',
    ],
  ),
];
