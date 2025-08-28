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
      name: json['name'],
      quantity: json['quantity']?.toDouble() ?? 0.0,
      unit: json['unit'],
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
