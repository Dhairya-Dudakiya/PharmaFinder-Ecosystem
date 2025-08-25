import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class InventoryScreen extends StatefulWidget {
  final String adminId;

  const InventoryScreen({super.key, required this.adminId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];

  String? _storeName;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<DatabaseEvent>? _medicinesSubscription;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStoreNameAndInit();
    _searchController.addListener(_filterMedicines);
  }

  @override
  void dispose() {
    _medicinesSubscription?.cancel();
    _searchController.removeListener(_filterMedicines);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStoreNameAndInit() async {
    try {
      final doc = await _firestore
          .collection("admins")
          .doc(widget.adminId)
          .get();

      if (mounted) {
        if (doc.exists && doc.data() != null) {
          setState(() {
            _storeName = doc.data()!['storeName'];
          });
          _listenToMedicines();
        } else {
          setState(() {
            _storeName = "Unknown Store";
            _errorMessage = "Store configuration not found for this admin.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _storeName = "Error";
          _errorMessage = "Failed to load store data. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  void _listenToMedicines() {
    if (_storeName == null) return;

    final medicinesRef = _db.ref("medicines/$_storeName");

    _medicinesSubscription = medicinesRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;

        if (data == null) {
          if (mounted) {
            setState(() {
              _allMedicines = [];
              _filteredMedicines = [];
              _isLoading = false;
            });
          }
          return;
        }

        if (data is! Map) {
          if (mounted) {
            setState(() {
              _allMedicines = [];
              _filteredMedicines = [];
              _isLoading = false;
              _errorMessage = "Unexpected data format in database.";
            });
          }
          return;
        }

        final List<Map<String, dynamic>> loadedMeds = [];
        final dataMap = Map<dynamic, dynamic>.from(data);

        dataMap.forEach((key, value) {
          if (value is Map) {
            final medData = Map<String, dynamic>.from(value);
            medData['id'] = key;
            loadedMeds.add(medData);
          }
        });

        if (mounted) {
          setState(() {
            loadedMeds.sort(
              (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
            );
            _allMedicines = loadedMeds;
            _filteredMedicines = _allMedicines;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to listen to inventory updates: $error";
            _isLoading = false;
          });
        }
      },
    );
  }

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedicines = _allMedicines.where((med) {
        final name = med['name']?.toLowerCase() ?? '';
        final category = med['category']?.toLowerCase() ?? '';
        return name.contains(query) || category.contains(query);
      }).toList();
    });
  }

  Future<void> _addOrEditMedicine({
    required String medId,
    required Map<String, dynamic> medData,
  }) async {
    if (_storeName == null) return;
    try {
      await _db.ref("medicines/$_storeName/$medId").set(medData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving medicine: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _deleteMedicine(String medId) async {
    if (_storeName == null) return;
    try {
      await _db.ref("medicines/$_storeName/$medId").remove();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting medicine: ${e.toString()}")),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String medId, String medName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete "$medName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () {
              _deleteMedicine(medId);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showMedicineDialog({Map<String, dynamic>? medicine}) {
    final isEditMode = medicine != null;

    final idController = TextEditingController(text: medicine?['id'] ?? '');
    final nameController = TextEditingController(text: medicine?['name'] ?? '');
    final categoryController = TextEditingController(
      text: medicine?['category'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: medicine?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: medicine?['price']?.toString() ?? '',
    );
    final dosageController = TextEditingController(
      text: medicine?['dosage'] ?? '',
    );
    final manufacturerController = TextEditingController(
      text: medicine?['manufacturer'] ?? '',
    );
    bool requiresPrescription = medicine?['requiresPrescription'] ?? false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditMode ? 'Edit Medicine' : 'Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  idController,
                  'ID (e.g., M001)',
                  enabled: !isEditMode,
                ),
                _buildTextField(nameController, 'Name'),
                _buildTextField(categoryController, 'Category'),
                _buildTextField(descriptionController, 'Description'),
                _buildTextField(
                  priceController,
                  'Price',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(dosageController, 'Dosage'),
                _buildTextField(manufacturerController, 'Manufacturer'),
                CheckboxListTile(
                  title: const Text('Requires Prescription?'),
                  value: requiresPrescription,
                  onChanged: (v) =>
                      setStateDialog(() => requiresPrescription = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final medId = idController.text.trim();
                if (medId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medicine ID cannot be empty.'),
                    ),
                  );
                  return;
                }

                if (!isEditMode && _allMedicines.any((m) => m['id'] == medId)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ID "$medId" already exists.'),
                    ),
                  );
                  return;
                }

                final medData = {
                  'name': nameController.text.trim(),
                  'category': categoryController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                  'dosage': dosageController.text.trim(),
                  'manufacturer': manufacturerController.text.trim(),
                  'requiresPrescription': requiresPrescription,
                };

                await _addOrEditMedicine(medId: medId, medData: medData);

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(isEditMode ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !enabled,
          fillColor: Colors.grey[200],
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _storeName ?? "Loading...",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showMedicineDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 16),
          ),
        ),
      );
    }

    if (_allMedicines.isEmpty) {
      return const Center(
        child: Text(
          'No medicines in inventory.\nTap the "+" button to add one!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (_filteredMedicines.isEmpty) {
      return const Center(
        child: Text(
          'No medicines found for your search.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.79,
      ),
      itemCount: _filteredMedicines.length,
      itemBuilder: (context, index) {
        final med = _filteredMedicines[index];
        return _MedicineCard(
          medicine: med,
          onEdit: () => _showMedicineDialog(medicine: med),
          onDelete: () => _showDeleteConfirmationDialog(med['id'], med['name']),
        );
      },
    );
  }
}

// This widget remains the same as the previous fix, as the problem is in the GridView's aspect ratio.
class _MedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.teal.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Section (Header) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(
                      Icons.medication_liquid,
                      color: Colors.teal,
                    ),
                  ),
                  if (medicine['requiresPrescription'] == true)
                    const Icon(
                      Icons.description,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),

              // This flexible layout is correct.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine['category'] ?? 'Uncategorized',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${medicine['price'] ?? 0.0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Bottom Section (Buttons) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
