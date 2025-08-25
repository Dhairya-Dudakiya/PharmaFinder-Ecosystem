import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  LatLng? _customerLocation;

  Future<void> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _customerLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('customerLocation'),
              position: _customerLocation!,
              infoWindow: const InfoWindow(title: 'Delivery Location'),
            ),
          );
        });
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _customerLocation!, zoom: 15),
          ),
        );
      }
    } catch (e) {
      print("Error geocoding address: $e");
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 6)}'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final customerAddress = orderData['address'] ?? '';

          if (_customerLocation == null && customerAddress.isNotEmpty) {
            _geocodeAddress(customerAddress);
          }

          return Column(
            children: [
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        _customerLocation ??
                        const LatLng(22.3039, 70.8022), // Default
                    zoom: 12,
                  ),
                  onMapCreated: (controller) =>
                      _mapController.complete(controller),
                  markers: _markers,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Customer: ${orderData['customerName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('Address: $customerAddress'),
                    Text(
                      'Total: ₹${orderData['totalAmount'].toStringAsFixed(2)}',
                    ),
                    const Divider(height: 20),
                    const Text(
                      'Update Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children:
                          [
                            'accepted',
                            'out_for_delivery',
                            'delivered',
                            'cancelled',
                          ].map((status) {
                            return ActionChip(
                              label: Text(status),
                              onPressed: () => _updateOrderStatus(status),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
