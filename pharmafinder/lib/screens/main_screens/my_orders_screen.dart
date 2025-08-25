import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your orders.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query for orders that belong to the current user
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
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
                'You have not placed any orders yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
      ),
    );
  }
}

// A dedicated widget to display a single order card
class _OrderCard extends StatelessWidget {
  final DocumentSnapshot orderSnapshot;

  const _OrderCard({required this.orderSnapshot});

  @override
  Widget build(BuildContext context) {
    final data = orderSnapshot.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('d MMM yyyy, h:mm a').format(timestamp)
        : 'N/A';
    final status = data['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderSnapshot.id.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('From: ${data['storeName'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text(
              'Total: ₹${data['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
            ),
            const SizedBox(height: 16),
            _OrderStatusTracker(currentStatus: status),
          ],
        ),
      ),
    );
  }
}

// A widget to visually track the order status
class _OrderStatusTracker extends StatelessWidget {
  final String currentStatus;
  const _OrderStatusTracker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = ['pending', 'accepted', 'out_for_delivery', 'delivered'];
    final currentIndex = statuses.indexOf(currentStatus.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(statuses.length, (index) {
            final isCompleted = index <= currentIndex;
            final color = isCompleted ? Colors.teal : Colors.grey[300];
            return Expanded(
              child: Column(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statuses[index].replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 10, color: color),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
