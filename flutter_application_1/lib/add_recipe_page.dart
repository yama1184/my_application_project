// lib/add_recipe_page.dart
import 'package:flutter/material.dart';
import 'recipe_data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddRecipePage extends StatefulWidget {
  final Function(Recipe recipe) onRecipeRegistered;
  final Recipe? initialRecipe;
  final Function(Recipe originalRecipe, Recipe updatedRecipe)? onRecipeEdited;

  const AddRecipePage({
    super.key,
    required this.onRecipeRegistered,
    this.initialRecipe,
    this.onRecipeEdited,
  });

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late String _recipeName;
  late String _imagePath;
  late Map<String, Map<String, dynamic>> _ingredients;
  late List<String> _instructions;
  final TextEditingController _instructionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipe != null) {
      _recipeName = widget.initialRecipe!.name;
      _imagePath = widget.initialRecipe!.imagePath;
      _ingredients = Map.from(widget.initialRecipe!.ingredients);
      _instructions = List.from(widget.initialRecipe!.instructions);
    } else {
      _recipeName = '';
      _imagePath = 'assets/placeholder.jpg';
      _ingredients = {};
      _instructions = [];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredients['新しい材料'] = {'quantity': 0.0, 'unit': ''};
    });
  }

  void _removeIngredient(String name) {
    setState(() {
      _ingredients.remove(name);
    });
  }

  void _updateIngredientName(String oldName, String newName) {
    if (oldName != newName) {
      final details = _ingredients[oldName];
      _ingredients.remove(oldName);
      _ingredients[newName] = details!;
    }
  }

  void _updateIngredientQuantity(String name, double quantity) {
    setState(() {
      _ingredients[name]!['quantity'] = quantity;
    });
  }

  void _updateIngredientUnit(String name, String unit) {
    setState(() {
      _ingredients[name]!['unit'] = unit;
    });
  }

  void _addInstruction() {
    if (_instructionController.text.isNotEmpty) {
      setState(() {
        _instructions.add(_instructionController.text);
        _instructionController.clear();
      });
    }
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }

  void _saveRecipe() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newRecipe = Recipe(
        name: _recipeName,
        imagePath: _imagePath,
        ingredients: _ingredients,
        instructions: _instructions,
      );
      if (widget.initialRecipe != null) {
        widget.onRecipeEdited!(widget.initialRecipe!, newRecipe);
      } else {
        widget.onRecipeRegistered(newRecipe);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRecipe == null ? 'レシピ登録' : 'レシピ編集'),
        actions: [
          if (widget.initialRecipe != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                Navigator.of(context).pop('delete');
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: _imagePath.startsWith('assets/')
                      ? Image.asset(
                          _imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 50);
                          },
                        )
                      : Image.file(
                          File(_imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 50);
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _recipeName,
                decoration: const InputDecoration(labelText: 'レシピ名'),
                onChanged: (value) => _recipeName = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'レシピ名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('材料',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._ingredients.keys.map((name) {
                return Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: '材料名'),
                        onChanged: (value) =>
                            _updateIngredientName(name, value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue:
                            _ingredients[name]!['quantity'].toString(),
                        decoration: const InputDecoration(labelText: '量'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateIngredientQuantity(
                            name, double.tryParse(value) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: _ingredients[name]!['unit'],
                        decoration: const InputDecoration(labelText: '単位'),
                        onChanged: (value) =>
                            _updateIngredientUnit(name, value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeIngredient(name),
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('材料を追加'),
              ),
              const SizedBox(height: 16),
              const Text('作り方',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._instructions.asMap().entries.map((entry) {
                int index = entry.key;
                String instruction = entry.value;
                return ListTile(
                  title: Text('${index + 1}. $instruction'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeInstruction(index),
                  ),
                );
              }).toList(),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instructionController,
                      decoration: const InputDecoration(labelText: '作り方を入力'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addInstruction,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveRecipe,
                child: Text(widget.initialRecipe == null ? 'レシピを登録' : 'レシピを更新'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
