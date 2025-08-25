// models/user_model.dart
class AppUser {
  final String uid;
  final String email;
  final String username;
  final String? fullName;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.fullName,
    this.phone,
    this.address,
    required this.createdAt,
  });
}
