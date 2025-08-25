import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // ✅ FIX: Check the 'admins' collection instead of 'riders'.
        final adminDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get();

        if (!adminDoc.exists) {
          await _auth.signOut();
          throw Exception(
            'Access Denied: This account is not registered as an admin.',
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Failed to sign in: ${e.message}');
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}
