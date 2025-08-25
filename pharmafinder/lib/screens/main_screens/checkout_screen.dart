import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import for LatLng
import 'package:pharmafinder/models/cart_item_model.dart';
import 'package:pharmafinder/screens/main_screens/map_selection_screen.dart';
import 'package:provider/provider.dart';

// ✅ ViewModel is updated to handle LatLng
class CheckoutViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isPlacingOrder = false;
  bool get isPlacingOrder => _isPlacingOrder;

  bool _saveAddress = false;
  bool get saveAddress => _saveAddress;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  void setSaveAddress(bool value) {
    _saveAddress = value;
    notifyListeners();
  }

  Future<Map<String, String>> getUserData() async {
    if (_currentUser == null) return {'name': '', 'address': ''};
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      final name = doc.data()?['name'] ?? '';
      final address = doc.data()?['address'] ?? '';
      return {'name': name, 'address': address};
    } catch (e) {
      return {'name': '', 'address': ''};
    }
  }

  // ✅ IMPROVED: This function now accepts and saves the precise location
  Future<bool> placeOrder({
    required String name,
    required String address,
    required LatLng? location, // Added location parameter
    required List<CartItem> cartItems,
  }) async {
    if (address.trim().isEmpty || name.trim().isEmpty) {
      _errorMessage = 'Please enter your name and delivery address.';
      notifyListeners();
      return false;
    }
    if (location == null) {
      _errorMessage = 'Please select a precise delivery location on the map.';
      notifyListeners();
      return false;
    }

    if (_currentUser == null) {
      _errorMessage = 'You must be logged in to place an order.';
      notifyListeners();
      return false;
    }

    _isPlacingOrder = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, List<CartItem>> itemsByStore = {};
      for (var item in cartItems) {
        final storeName = item.medicine.storeName;
        if (storeName != null) {
          (itemsByStore[storeName] ??= []).add(item);
        }
      }

      final batch = _firestore.batch();

      for (var storeName in itemsByStore.keys) {
        final storeItems = itemsByStore[storeName]!;
        final storeTotal = storeItems.fold<double>(
          0,
          (sum, item) => sum + (item.medicine.price * item.quantity),
        );

        final orderRef = _firestore.collection('orders').doc();

        batch.set(orderRef, {
          'orderId': orderRef.id,
          'userId': _currentUser!.uid,
          'customerName': name.trim(),
          'address': address.trim(),
          // ✅ NEW: Save the precise latitude and longitude to the order
          'customerLat': location.latitude,
          'customerLng': location.longitude,
          'totalAmount': storeTotal,
          'storeName': storeName,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        for (final item in storeItems) {
          if (item.medicine.id.isNotEmpty) {
            final itemRef = orderRef.collection('items').doc(item.medicine.id);
            batch.set(itemRef, {
              'name': item.medicine.name,
              'price': item.medicine.price,
              'quantity': item.quantity,
            });
          }
        }
      }

      if (_saveAddress) {
        batch.update(_firestore.collection('users').doc(_currentUser!.uid), {
          'address': address.trim(),
        });
      }

      final cartCollection = _firestore
          .collection('carts')
          .doc(_currentUser!.uid)
          .collection('items');
      final cartSnapshot = await cartCollection.get();
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to place order: ${e.toString()}';
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }
}

class CheckoutScreen extends StatelessWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutViewModel(),
      child: _CheckoutScreenContent(
        cartItems: cartItems,
        totalAmount: totalAmount,
      ),
    );
  }
}

class _CheckoutScreenContent extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const _CheckoutScreenContent({
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<_CheckoutScreenContent> createState() => _CheckoutScreenContentState();
}

class _CheckoutScreenContentState extends State<_CheckoutScreenContent> {
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  // ✅ NEW: State variable to hold the coordinates from the map
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    context.read<CheckoutViewModel>().getUserData().then((userData) {
      if (mounted) {
        _nameController.text = userData['name']!;
        _addressController.text = userData['address']!;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final viewModel = context.read<CheckoutViewModel>();
    final success = await viewModel.placeOrder(
      name: _nameController.text,
      address: _addressController.text,
      location: _selectedLocation, // Pass the coordinates
      cartItems: widget.cartItems,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ IMPROVED: This function now handles the map result correctly
  Future<void> _openMapSelection() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
    );

    if (result != null &&
        result['address'] != null &&
        result['location'] != null) {
      setState(() {
        _addressController.text = result['address'];
        _selectedLocation = result['location'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CheckoutViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Order Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ...widget.cartItems.map(
                    (item) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: const Icon(
                          Icons.medication_outlined,
                          color: Colors.teal,
                        ),
                      ),
                      title: Text(item.medicine.name),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text(
                        '₹${(item.medicine.price * item.quantity).toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Delivery Details'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.home_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.map_outlined,
                          color: Colors.teal,
                        ),
                        onPressed: _openMapSelection,
                        tooltip: 'Select on Map',
                      ),
                    ),
                    maxLines: 3,
                  ),
                  CheckboxListTile(
                    title: const Text("Save this address for future orders"),
                    value: viewModel.saveAddress,
                    onChanged: (value) => viewModel.setSaveAddress(value!),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total to Pay:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.isPlacingOrder ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              child: viewModel.isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirm and Place Order',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
}
