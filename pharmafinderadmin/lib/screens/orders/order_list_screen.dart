import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pharmafinderadmin/screens/orders/order_details_screen.dart'; // We will create this next

class OrderListScreen extends StatefulWidget {
  final String adminId;
  const OrderListScreen({super.key, required this.adminId});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<String?> _storeNameFuture;

  @override
  void initState() {
    super.initState();
    _storeNameFuture = _fetchStoreName(widget.adminId);
  }

  Future<String?> _fetchStoreName(String adminId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .get();
      return doc.data()?['storeName'];
    } catch (e) {
      print("Error fetching store name: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Orders'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<String?>(
        future: _storeNameFuture,
        builder: (context, storeSnapshot) {
          if (storeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (storeSnapshot.hasError ||
              !storeSnapshot.hasData ||
              storeSnapshot.data == null) {
            return const Center(
              child: Text('Could not load store information.'),
            );
          }

          final storeName = storeSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('storeName', isEqualTo: storeName)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (orderSnapshot.hasError) {
                return Center(child: Text('Error: ${orderSnapshot.error}'));
              }
              if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No orders found for this store.'),
                );
              }

              final orders = orderSnapshot.data!.docs;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final formattedDate = timestamp != null
                      ? DateFormat('d MMM yyyy, h:mm a').format(timestamp)
                      : 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(
                        'Order from ${data['customerName'] ?? 'N/A'}',
                      ),
                      subtitle: Text(
                        'Total: ₹${data['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      trailing: Chip(label: Text(data['status'] ?? 'pending')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailsScreen(orderId: order.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
