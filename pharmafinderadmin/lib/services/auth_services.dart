import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 🔐 Register Admin and Create Store in Realtime DB
  Future<User?> registerAdmin({
    required String email,
    required String password,
    required String storeName,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Save admin details in Firestore
        await _firestore.collection('admins').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'storeName': storeName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create store entry in Realtime Database under /medicines/{storeName}
        await _dbRef.child("medicines").child(storeName).set({
          "storeName": storeName,
          "createdAt": ServerValue.timestamp,
        });
      }

      return user;
    } catch (e) {
      print('Error registering admin: $e');
      rethrow;
    }
  }

  // 🔐 Login Admin
  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Optional: Check if user is an admin
      final isAdmin = await _firestore
          .collection('admins')
          .doc(user!.uid)
          .get();
      if (!isAdmin.exists) {
        throw FirebaseAuthException(
          code: 'not-admin',
          message: 'This user is not registered as an admin.',
        );
      }

      return user;
    } catch (e) {
      print('Error logging in admin: $e');
      rethrow;
    }
  }

  // 🔓 Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 👤 Get current admin
  User? getCurrentAdmin() {
    return _auth.currentUser;
  }

  // ✅ Check if logged-in user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('admins').doc(user.uid).get();
    return doc.exists;
  }
}
