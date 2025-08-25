import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription? _orderSubscription;
  Map<String, dynamic>? _orderData;
  Set<Marker> _markers = {};
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _listenToOrder();
    _determinePosition();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _listenToOrder() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
          if (mounted && snapshot.exists) {
            setState(() {
              _orderData = snapshot.data();
            });
            _updateMarkers();
          }
        });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
    _updateMarkers();
  }

  Future<String?> _getStoreAddress(String storeName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('storeName', isEqualTo: storeName)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['address'];
      }
    } catch (e) {
      print("Error fetching store address: $e");
    }
    return null;
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Error geocoding address '$address': $e");
    }
    return null;
  }

  // ✅ IMPROVED: This function now uses the precise coordinates from the order document.
  Future<void> _updateMarkers() async {
    if (_orderData == null || _currentPosition == null) return;

    final storeName = _orderData!['storeName'] ?? '';
    final storeAddress = await _getStoreAddress(storeName);

    // Get the precise customer coordinates directly from the order data
    final double? customerLat = _orderData!['customerLat'];
    final double? customerLng = _orderData!['customerLng'];

    if (storeAddress == null || customerLat == null || customerLng == null)
      return;

    final storeLatLng = await _getLatLngFromAddress(storeAddress);
    if (storeLatLng == null) return;

    // Use the precise coordinates instead of geocoding the address string
    final customerLatLng = LatLng(customerLat, customerLng);

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('rider'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('store'),
        position: storeLatLng,
        infoWindow: InfoWindow(title: 'Pickup: $storeName'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: customerLatLng, // Use the precise coordinates
        infoWindow: InfoWindow(
          title: 'Drop-off: ${_orderData!['customerName']}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        _createBounds([
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          storeLatLng,
          customerLatLng,
        ]),
        100.0, // Padding
      ),
    );
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    final southwestLon = positions
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    final northeastLat = positions
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    final northeastLon = positions
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);
    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLon),
      northeast: LatLng(northeastLat, northeastLon),
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to "$newStatus"'),
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

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phoneNumber')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 6)}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _orderData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : const LatLng(22.3039, 70.8022), // Default location
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _markers,
                ),
                _buildOrderDraggableSheet(),
              ],
            ),
    );
  }

  Widget _buildOrderDraggableSheet() {
    final status = _orderData!['status'] ?? 'pending';
    final customerPhone = _orderData!['userPhone'];

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.2)),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.green),
                title: const Text(
                  'Pickup From',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_orderData!['storeName'] ?? 'N/A'),
              ),
              ListTile(
                leading: const Icon(Icons.person_pin_circle, color: Colors.red),
                title: const Text(
                  'Deliver To',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${_orderData!['customerName']}\n${_orderData!['address']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: Colors.teal),
                  onPressed: () => _makePhoneCall(customerPhone),
                ),
              ),
              const Divider(),
              if (status == 'accepted')
                ElevatedButton.icon(
                  icon: const Icon(Icons.motorcycle, color: Colors.white),
                  onPressed: () => _updateOrderStatus('out_for_delivery'),
                  label: const Text(
                    'Start Delivery',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              if (status == 'out_for_delivery')
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  onPressed: () => _updateOrderStatus('delivered'),
                  label: const Text(
                    'Mark as Delivered',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              if (status == 'delivered')
                const Center(
                  child: Text(
                    'This order has been completed.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
