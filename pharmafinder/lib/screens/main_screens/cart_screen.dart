import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmafinder/models/cart_item_model.dart';
import 'package:pharmafinder/screens/main_screens/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<CartItem>>? _cartStream;
  Stream<List<CartItem>>? get cartStream => _cartStream;

  CartViewModel() {
    _fetchCartItems();
  }

  void _fetchCartItems() {
    if (_currentUser == null) return;

    final cartRef = _firestore
        .collection('carts')
        .doc(_currentUser.uid)
        .collection('items')
        .orderBy('addedAt', descending: true);

    _cartStream = cartRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return CartItem.fromJson(doc.data(), doc.id);
      }).toList(),
    );
    notifyListeners();
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (_currentUser == null) return;
    final docRef = _firestore
        .collection('carts')
        .doc(_currentUser.uid)
        .collection('items')
        .doc(itemId);

    if (newQuantity > 0) {
      await docRef.update({'quantity': newQuantity});
    } else {
      await docRef.delete();
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_currentUser == null) return;
    await _firestore
        .collection('carts')
        .doc(_currentUser.uid)
        .collection('items')
        .doc(itemId)
        .delete();
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the ViewModel to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => CartViewModel(),
      child: const _CartScreenContent(),
    );
  }
}

class _CartScreenContent extends StatelessWidget {
  const _CartScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CartViewModel>();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your cart')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('My Cart'),
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: viewModel.cartStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const _EmptyCartView();
          }

          final cartItems = snapshot.data!;
          final total = cartItems.fold<double>(
            0,
            (sum, item) => sum + (item.medicine.price * item.quantity),
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    return _CartItemCard(item: cartItems[index]);
                  },
                ),
              ),
              _CheckoutBar(totalAmount: total, cartItems: cartItems),
            ],
          );
        },
      ),
    );
  }
}

// ✅ NEW: A dedicated widget for the cart item card for better organization.
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<CartViewModel>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.teal.shade50,
              child: const Icon(
                Icons.medication_outlined,
                color: Colors.teal,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicine.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.medicine.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.teal, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  onPressed: () =>
                      viewModel.updateQuantity(item.id, item.quantity - 1),
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: () =>
                      viewModel.updateQuantity(item.id, item.quantity + 1),
                ),
              ],
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () =>
                  _showDeleteConfirmation(context, viewModel, item),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Confirmation dialog to prevent accidental deletion.
  void _showDeleteConfirmation(
    BuildContext context,
    CartViewModel viewModel,
    CartItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text(
          'Are you sure you want to remove "${item.medicine.name}" from your cart?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
            onPressed: () {
              viewModel.removeItem(item.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item removed from cart')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: A persistent bottom bar for the total and checkout button.
class _CheckoutBar extends StatelessWidget {
  final double totalAmount;
  final List<CartItem> cartItems;
  const _CheckoutBar({required this.totalAmount, required this.cartItems});

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${totalAmount.toStringAsFixed(2)}',
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutScreen(
                    totalAmount: totalAmount,
                    cartItems: cartItems,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: A more engaging view for when the cart is empty.
class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'Your Cart is Empty',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Looks like you haven\'t added anything to your cart yet.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // Go back to home
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Shop Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
