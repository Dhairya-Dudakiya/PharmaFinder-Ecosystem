import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmafinder/models/medicine_model.dart';
import 'package:pharmafinder/utils/icon_helper.dart';
import 'package:pharmafinder/screens/main_screens/cart_screen.dart';
import 'package:provider/provider.dart';

class MedicineDetailViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _quantity = 1;
  int get quantity => _quantity;

  Map<String, dynamic>? _storeData;
  Map<String, dynamic>? get storeData => _storeData;

  bool _isLoadingStore = true;
  bool get isLoadingStore => _isLoadingStore;

  bool _isAddingToCart = false;
  bool get isAddingToCart => _isAddingToCart;

  MedicineDetailViewModel(String storeName) {
    _fetchStoreDetails(storeName);
  }

  void incrementQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }

  // ✅ FIXED: This function now correctly fetches store details from Cloud Firestore.
  Future<void> _fetchStoreDetails(String storeName) async {
    try {
      // Query the 'admins' collection in Firestore where the storeName matches.
      final querySnapshot = await _firestore
          .collection('admins')
          .where('storeName', isEqualTo: storeName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _storeData = querySnapshot.docs.first.data();
      }
    } catch (e) {
      print("Error fetching store details: $e");
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(Medicine medicine) async {
    if (_currentUser == null) {
      return false; // User not logged in
    }

    _isAddingToCart = true;
    notifyListeners();

    try {
      final cartItemRef = _firestore
          .collection('carts')
          .doc(_currentUser!.uid)
          .collection('items')
          .doc(medicine.id);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(cartItemRef);

        if (docSnapshot.exists) {
          transaction.update(cartItemRef, {
            'quantity': FieldValue.increment(_quantity),
          });
        } else {
          transaction.set(cartItemRef, {
            'medicineId': medicine.id,
            'name': medicine.name,
            'price': medicine.price,
            'quantity': _quantity,
            'storeName': medicine.storeName,
            'icon': medicine.icon,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return true;
    } catch (e) {
      print("Error adding to cart: $e");
      return false;
    } finally {
      _isAddingToCart = false;
      notifyListeners();
    }
  }
}

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicineDetailViewModel(medicine.storeName ?? ''),
      child: _MedicineDetailView(medicine: medicine),
    );
  }
}

class _MedicineDetailView extends StatelessWidget {
  final Medicine medicine;

  const _MedicineDetailView({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MedicineDetailViewModel>();
    final totalAmount = medicine.price * viewModel.quantity;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text(medicine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('Details'),
            _buildDetailsCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Description'),
            Text(
              medicine.description,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Sold By'),
            _buildStoreCard(viewModel),
            const SizedBox(height: 100), // Space for the bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, viewModel, totalAmount),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal.withOpacity(0.1),
            child: Icon(
              getMedicineIcon(medicine.icon),
              size: 50,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            medicine.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            medicine.dosage,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Category', medicine.category),
            _buildInfoRow('Manufacturer', medicine.manufacturer),
            _buildInfoRow(
              'Prescription',
              medicine.requiresPrescription ? 'Required' : 'Not Required',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(MedicineDetailViewModel viewModel) {
    if (viewModel.isLoadingStore) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.storeData == null) {
      return const Card(
        child: ListTile(title: Text("Store information not available.")),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.storefront, color: Colors.teal),
        title: Text(
          viewModel.storeData!['storeName'] ?? 'Unknown Store',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          viewModel.storeData!['address'] ?? 'Address not available',
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    MedicineDetailViewModel viewModel,
    double totalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Quantity Selector
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.teal),
                onPressed: viewModel.decrementQuantity,
              ),
              Text(
                viewModel.quantity.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: viewModel.incrementQuantity,
              ),
            ],
          ),
          // Add to Cart Button
          ElevatedButton.icon(
            onPressed: viewModel.isAddingToCart
                ? null
                : () async {
                    final success = await viewModel.addToCart(medicine);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Added to cart!'
                                : 'Failed to add. Please log in.',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: viewModel.isAddingToCart
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: Text(
              'Add (₹${totalAmount.toStringAsFixed(2)})',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
