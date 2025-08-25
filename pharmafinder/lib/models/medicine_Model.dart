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
  final String? storeId; // Store reference
  final String? storeName; // Optional for quick display

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
    this.storeId,
    this.storeName,
  });

  /// From JSON (Realtime DB or API)
  factory Medicine.fromJson(Map<String, dynamic> json, {String? storeName}) {
    return Medicine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: _parsePrice(json['price']),
      dosage: json['dosage']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      requiresPrescription: _parseBool(json['requiresPrescription']),
      icon: json['icon']?.toString() ?? 'medication',
      storeId: json['storeId']?.toString(),
      storeName:
          storeName ?? json['storeName']?.toString(), // ✅ Prefer parent key
    );
  }

  /// From Firestore
  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      price: _parsePrice(data['price']),
      dosage: data['dosage']?.toString() ?? '',
      manufacturer: data['manufacturer']?.toString() ?? '',
      requiresPrescription: _parseBool(data['requiresPrescription']),
      icon: data['icon']?.toString() ?? 'medication',
      storeId: data['storeId']?.toString(),
      storeName: data['storeName']?.toString(),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'dosage': dosage,
      'manufacturer': manufacturer,
      'requiresPrescription': requiresPrescription,
      'icon': icon,
      if (storeId != null) 'storeId': storeId,
      if (storeName != null) 'storeName': storeName,
    };
  }

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
    String? storeId,
    String? storeName,
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
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
    );
  }

  /// Helper to safely parse price
  static double _parsePrice(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  /// Helper to parse bool from various formats
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }
}
