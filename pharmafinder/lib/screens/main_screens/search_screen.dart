import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pharmafinder/models/medicine_model.dart';
import 'package:pharmafinder/screens/main_screens/medicine_detail_screen.dart'; // ✅ IMPORT: Added the detail screen
import 'package:pharmafinder/utils/icon_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Medicine> _allMedicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllMedicinesFromAllStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMedicinesFromAllStores() async {
    try {
      final snapshot = await _dbRef.child('medicines').get();

      if (snapshot.exists && snapshot.value != null) {
        final allStoresData = Map<String, dynamic>.from(snapshot.value as Map);
        List<Medicine> loadedMedicines = [];

        allStoresData.forEach((storeName, storeInventory) {
          if (storeInventory is Map) {
            final medicinesMap = Map<String, dynamic>.from(storeInventory);

            medicinesMap.forEach((medicineId, medicineData) {
              if (medicineData is Map) {
                try {
                  final fullMedicineData = Map<String, dynamic>.from(
                    medicineData,
                  );
                  fullMedicineData['storeName'] = storeName;
                  fullMedicineData['id'] = medicineId;

                  loadedMedicines.add(Medicine.fromJson(fullMedicineData));
                } catch (e) {
                  debugPrint(
                    "Error parsing medicine $medicineId in store $storeName: $e",
                  );
                }
              }
            });
          }
        });

        if (mounted) {
          setState(() {
            _allMedicines = loadedMedicines;
            _filteredMedicines = loadedMedicines;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading medicines: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Could not load medicines. Please try again later.";
          _isLoading = false;
        });
      }
    }
  }

  void _filterMedicines(String query) {
    final lowercasedQuery = query.toLowerCase();
    setState(() {
      _filteredMedicines = _allMedicines.where((medicine) {
        final medicineName = medicine.name.toLowerCase();
        final storeName = medicine.storeName?.toLowerCase() ?? '';
        return medicineName.contains(lowercasedQuery) ||
            storeName.contains(lowercasedQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search All Medicines'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMedicines,
              decoration: InputDecoration(
                hintText: 'Search by medicine or store name...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_allMedicines.isEmpty) {
      return const Center(child: Text('No medicines available in any store.'));
    }

    if (_filteredMedicines.isEmpty) {
      return const Center(child: Text('No medicines found for your search.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _filteredMedicines.length,
      itemBuilder: (context, index) {
        return _buildMedicineListItem(_filteredMedicines[index]);
      },
    );
  }

  Widget _buildMedicineListItem(Medicine medicine) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // ✅ FIX: Added navigation to the MedicineDetailScreen
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicineDetailScreen(medicine: medicine),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(getMedicineIcon(medicine.icon), color: Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.storeName ?? 'Unknown Store',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "₹${medicine.price}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
