// lib/pantry_list_data.dart
class PantryListData {
  String name;
  double quantity;
  String unit;

  PantryListData({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory PantryListData.fromJson(Map<String, dynamic> json) {
    return PantryListData(
      name: json['name'] as String,
      quantity: json['quantity'] as double,
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
