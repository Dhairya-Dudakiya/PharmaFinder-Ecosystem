class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double rating;
  final int reviewCount;
  final int deliveryTime;
  final bool isOpen;
  final String? imageUrl;
  final String phone;
  final List<String> services;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.isOpen,
    this.imageUrl,
    required this.phone,
    required this.services,
  });
}
