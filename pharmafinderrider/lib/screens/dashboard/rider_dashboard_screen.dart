import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pharmafinderrider/screens/dashboard/order_detail_screen.dart';
import 'package:pharmafinderrider/service/rider_auth_service.dart';

class RiderDashboardScreen extends StatefulWidget {
  final User user;
  const RiderDashboardScreen({super.key, required this.user});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RiderAuthService _authService = RiderAuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                await _authService.signOut();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'New Orders'),
            Tab(text: 'My Pickups'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderList(
            query: FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'pending')
                .orderBy('timestamp', descending: true),
          ),
          _OrderList(
            query: FirebaseFirestore.instance
                .collection('orders')
                .where('deliveryPersonId', isEqualTo: widget.user.uid)
                .where('status', whereIn: ['accepted', 'out_for_delivery'])
                .orderBy('timestamp', descending: true),
          ),
          _OrderList(
            query: FirebaseFirestore.instance
                .collection('orders')
                .where('deliveryPersonId', isEqualTo: widget.user.uid)
                .where('status', isEqualTo: 'delivered')
                .orderBy('timestamp', descending: true),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final Query query;
  const _OrderList({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No orders found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _OrderCard(orderSnapshot: orders[index]);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DocumentSnapshot orderSnapshot;
  const _OrderCard({required this.orderSnapshot});

  Future<void> _acceptOrder(BuildContext context, String orderId) async {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) return;

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'accepted', 'deliveryPersonId': riderId},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = orderSnapshot.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('d MMM, h:mm a').format(timestamp)
        : 'N/A';
    final status = data['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (status != 'pending') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: orderSnapshot.id),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ FIX: Wrapped the Text widget in an Expanded widget
                  // to prevent it from overflowing when the store name is long.
                  Expanded(
                    child: Text(
                      'Order from ${data['storeName'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis, // Added for safety
                    ),
                  ),
                  const SizedBox(width: 8), // Added space for safety
                  Chip(
                    label: Text(status.toUpperCase()),
                    backgroundColor: status == 'pending'
                        ? Colors.orange.shade100
                        : Colors.teal.shade100,
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow(
                Icons.person_outline,
                'Customer:',
                data['customerName'] ?? 'N/A',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address:',
                data['address'] ?? 'N/A',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.currency_rupee,
                'Total:',
                '₹${data['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.timer_outlined, 'Placed at:', formattedDate),
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Accept Order',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _acceptOrder(context, orderSnapshot.id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
