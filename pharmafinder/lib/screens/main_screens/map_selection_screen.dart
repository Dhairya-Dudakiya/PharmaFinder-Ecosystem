import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _pickedLocation;
  String _pickedAddress = "Move the map to select a location";
  bool _isLoading = true;

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(22.3039, 70.8022), // Default to Rajkot
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _goToCurrentUserLocation();
  }

  // ✅ FIX: This function now has a timeout to prevent it from getting stuck.
  Future<void> _goToCurrentUserLocation() async {
    try {
      // Request position with a 10-second timeout.
      Position position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _pickedLocation = LatLng(position.latitude, position.longitude);
        });
        _getAddressFromLatLng(_pickedLocation!);
      }
    } catch (e) {
      print("Error getting current location: $e");
      // If it fails (e.g., timeout), still hide the loader so the user isn't stuck.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get current location. Please select manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      if (mounted) {
        setState(() {
          _pickedAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickedAddress = "Could not get address for this location.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Location'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kDefaultLocation,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onCameraMove: (CameraPosition position) {
              setState(() {
                _pickedLocation = position.target;
              });
            },
            onCameraIdle: () {
              if (_pickedLocation != null) {
                _getAddressFromLatLng(_pickedLocation!);
              }
            },
          ),
          const Center(
            child: Icon(Icons.location_pin, color: Colors.red, size: 50),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pickedAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _pickedLocation == null
                          ? null
                          : () {
                              Navigator.of(context).pop({
                                'address': _pickedAddress,
                                'location': _pickedLocation,
                              });
                            },
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
