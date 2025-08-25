// lib/models/cart_item_model.dart
import 'medicine_model.dart';

class CartItem {
  final String id;
  final Medicine medicine;
  final int quantity;

  CartItem({required this.id, required this.medicine, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json, String id) {
    return CartItem(
      id: id,
      medicine: Medicine.fromJson(json),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, ...medicine.toJson(), 'quantity': quantity};
  }
}