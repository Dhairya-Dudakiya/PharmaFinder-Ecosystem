import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String dosage;
  final String manufacturer;
  final bool requiresPrescription;
  final String icon;
  final String store;

  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.dosage,
    required this.manufacturer,
    required this.requiresPrescription,
    required this.icon,
    required this.store,
  });

  // From JSON (The single source of truth for parsing)
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] is double)
          ? json['price']
          : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      dosage: json['dosage']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      requiresPrescription: json['requiresPrescription'] == true,
      icon: json['icon']?.toString() ?? 'medication',
      store: json['store']?.toString() ?? '',
    );
  }

  // ✨ REFINED: fromFirestore now uses fromJson to avoid repeated code.
  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Add the document ID into the map
    return Medicine.fromJson(data); // Call the main factory
  }

  // To JSON (for writing to DB)
  Map<String, dynamic> toJson() {
    return {
      // 'id' is often omitted here for Firestore writes, as the doc.id is the source of truth.
      // But including it can be useful for other scenarios. Your choice is fine.
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'dosage': dosage,
      'manufacturer': manufacturer,
      'requiresPrescription': requiresPrescription,
      'icon': icon,
      'store': store,
    };
  }

  // copyWith method (no changes needed, it's perfect)
  Medicine copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? dosage,
    String? manufacturer,
    bool? requiresPrescription,
    String? icon,
    String? store,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      dosage: dosage ?? this.dosage,
      manufacturer: manufacturer ?? this.manufacturer,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      icon: icon ?? this.icon,
      store: store ?? this.store,
    );
  }
}
