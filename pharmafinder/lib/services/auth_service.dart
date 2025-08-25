import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/medicine_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // 🔹 Auth state listener
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔹 Login user
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // 🔹 Register user
  Future<User?> register(String email, String password, String username) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // 🔹 Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // 🔹 Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 🔹 Get user profile
  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>;
  }

  // ==============================
  // 📦 Store & Medicine Methods
  // ==============================

  // 🔹 Get all stores (from Firestore)
  Future<List<Map<String, dynamic>>> getAllStores() async {
    final snapshot = await _firestore.collection('stores').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // 🔹 Get store by ID (from Firestore)
  Future<Map<String, dynamic>?> getStoreById(String storeId) async {
    final doc = await _firestore.collection('stores').doc(storeId).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }

  // 🔹 Get all medicines (from Realtime Database)
  Future<List<Medicine>> getAllMedicines() async {
    final snapshot = await _database.child('medicines').get();
    if (!snapshot.exists) return [];

    List<Medicine> medicines = [];
    final data = snapshot.value as Map<dynamic, dynamic>;

    data.forEach((storeName, meds) {
      if (meds is Map) {
        meds.forEach((id, medData) {
          medicines.add(
            Medicine.fromJson({
              ...Map<String, dynamic>.from(medData),
              'id': id,
              'storeName': storeName,
            }),
          );
        });
      }
    });

    return medicines;
  }

  // 🔹 Get medicines by store name (from Realtime Database)
  Future<List<Medicine>> getMedicinesByStore(String storeName) async {
    final snapshot = await _database.child('medicines/$storeName').get();
    if (!snapshot.exists) return [];

    final medsData = snapshot.value as Map<dynamic, dynamic>;
    return medsData.entries.map((entry) {
      return Medicine.fromJson({
        ...Map<String, dynamic>.from(entry.value),
        'id': entry.key,
        'storeName': storeName,
      });
    }).toList();
  }

  // 🔹 Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Email is invalid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
