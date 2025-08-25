import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreDetailsScreen extends StatefulWidget {
  final String adminId;

  const StoreDetailsScreen({super.key, required this.adminId});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  Map<String, dynamic>? storeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStoreDetails();
  }

  Future<void> fetchStoreDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.adminId)
          .get();

      if (snapshot.exists) {
        setState(() {
          storeData = snapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          storeData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching store details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildInfoTile(String title, String? value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value ?? 'Not available'),
      leading: const Icon(Icons.info_outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeData == null
          ? const Center(child: Text("No store details found."))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  buildInfoTile("Store Name", storeData!['storeName']),
                  buildInfoTile("Owner Name", storeData!['ownerName']),
                  buildInfoTile("Email", storeData!['email']),
                  buildInfoTile("Phone Number", storeData!['phone']),
                  buildInfoTile("Location", storeData!['location']),
                  buildInfoTile("License Number", storeData!['licenseNumber']),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
