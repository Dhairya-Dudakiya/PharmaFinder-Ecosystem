import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user document
  Future<void> createUser(String uid, String email, String username) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user data
  Future<Map<String, dynamic>> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>;
  }

  // Update username
  Future<void> updateUsername(String uid, String newUsername) async {
    await _firestore.collection('users').doc(uid).update({
      'username': newUsername,
    });
  }
}
