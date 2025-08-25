import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pharmafinderadmin/screens/dashboard/inventory_screen.dart';
import 'package:pharmafinderadmin/screens/orders/order_list_screen.dart';
import 'package:pharmafinderadmin/screens/orders/store_details_screen.dart';
import 'package:pharmafinderadmin/screens/dashboard/add_rider_screen.dart';
import 'package:pharmafinderadmin/screens/dashboard/InquiryListScreen.dart';
import 'package:pharmafinderadmin/services/auth_services.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _cardsAnimated = false;

  Future<String>? _storeNameFuture;
  Future<int>? _inventoryCountFuture;
  Future<int>? _orderCountFuture;
  Future<int>? _inquiryCountFuture;
  Future<int>? _riderCountFuture;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _cardsAnimated = true;
        });
      }
    });
  }

  void _initializeFutures(String adminId) {
    if (_storeNameFuture == null) {
      setState(() {
        _storeNameFuture = _fetchStoreName(adminId);
        _inventoryCountFuture = _getInventoryCount(adminId);
        _orderCountFuture = _getOrderCount(adminId);
        _inquiryCountFuture = _getInquiryCount();
        _riderCountFuture =
            _getRiderCount(); // ✅ NEW: Initialize the rider count future
      });
    }
  }

  Future<String> _fetchStoreName(String adminId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['storeName'] ?? 'Admin Dashboard';
      }
    } catch (e) {
      print("Error fetching store name: $e");
    }
    return 'Admin Dashboard';
  }

  Future<int> _getInventoryCount(String adminId) async {
    final storeName = await _fetchStoreName(adminId);
    final snapshot = await FirebaseDatabase.instance
        .ref('medicines/$storeName')
        .get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      data.remove('isInitialized');
      return data.length;
    }
    return 0;
  }

  Future<int> _getOrderCount(String adminId) async {
    try {
      final storeName = await _fetchStoreName(adminId);
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('storeName', isEqualTo: storeName)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error fetching order count: $e");
      return 0;
    }
  }

  Future<int> _getInquiryCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('inquiries')
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error fetching inquiry count: $e");
      return 0;
    }
  }

  // ✅ NEW: Fetches the total number of registered riders.
  Future<int> _getRiderCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('riders')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error fetching rider count: $e");
      return 0;
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
              onPressed: () async {
                await AdminAuthService().signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text("Not logged in. Please restart or log in again."),
            ),
          );
        }

        final currentUser = snapshot.data!;
        final String adminId = currentUser.uid;

        _initializeFutures(adminId);

        if (_storeNameFuture == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, currentUser, _storeNameFuture!),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      // ✅ NEW: Increased item count to 5
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _buildAnimatedCard(
                          index: index,
                          child: _buildCardFromIndex(index, adminId),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFromIndex(int index, String adminId) {
    switch (index) {
      case 0:
        return _buildDashboardCard(
          context,
          icon: Icons.storefront,
          title: 'Store Details',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailsScreen(adminId: adminId),
            ),
          ),
        );
      case 1:
        return _buildDashboardCard(
          context,
          icon: Icons.inventory_2,
          title: 'Manage Inventory',
          metricFuture: _inventoryCountFuture,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventoryScreen(adminId: adminId),
            ),
          ),
        );
      case 2:
        return _buildDashboardCard(
          context,
          icon: Icons.receipt_long,
          title: 'Orders',
          metricFuture: _orderCountFuture,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderListScreen(adminId: adminId),
            ),
          ),
        );
      case 3:
        return _buildDashboardCard(
          context,
          icon: Icons.question_answer_outlined,
          title: 'Symptom Inquiries',
          metricFuture: _inquiryCountFuture,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InquiryListScreen()),
          ),
        );
      // ✅ NEW: Case for the "Add Rider" card
      case 4:
        return _buildDashboardCard(
          context,
          icon: Icons.person_add_alt_1_outlined,
          title: 'Manage Riders',
          metricFuture: _riderCountFuture,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRiderScreen()),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    final duration = Duration(milliseconds: 300 + (index * 100));
    return AnimatedOpacity(
      duration: duration,
      opacity: _cardsAnimated ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _cardsAnimated ? 0 : 50, 0),
        child: child,
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    User? user,
    Future<String> storeNameFuture,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A7B79), Color(0xFF39B9B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<String>(
                future: storeNameFuture,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: "Logout",
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? "Managing your store, inventory, and orders",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Future<int>? metricFuture,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.1),
              radius: 28,
              child: Icon(icon, size: 30, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (metricFuture != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: FutureBuilder<int>(
                  future: metricFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      );
                    }
                    return Text(
                      snapshot.data?.toString() ?? '0',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
