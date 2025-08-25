import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// A simple model to hold medicine data for selection
class SelectableMedicine {
  final String id;
  final String name;
  bool isSelected;

  SelectableMedicine({
    required this.id,
    required this.name,
    this.isSelected = false,
  });
}

class InquiryDetailScreen extends StatefulWidget {
  final String inquiryId;
  const InquiryDetailScreen({super.key, required this.inquiryId});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  final _responseTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // This will hold the medicines the admin suggests
  List<SelectableMedicine> _suggestedMedicines = [];

  // Fetches the admin's store name from their profile
  Future<String?> _getAdminStoreName() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(adminId)
        .get();
    return doc.data()?['storeName'];
  }

  // Shows a dialog to select medicines from the store's inventory
  Future<void> _showMedicineSelectorDialog() async {
    final storeName = await _getAdminStoreName();
    if (storeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not identify admin store.')),
      );
      return;
    }

    // Fetch all medicines from the Realtime Database for this store
    final snapshot = await FirebaseDatabase.instance
        .ref('medicines/$storeName')
        .get();
    if (!snapshot.exists || snapshot.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines found in your inventory.')),
      );
      return;
    }

    final allMedicines = <SelectableMedicine>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    data.forEach((key, value) {
      if (value is Map) {
        allMedicines.add(
          SelectableMedicine(id: key, name: value['name'] ?? 'Unknown'),
        );
      }
    });

    // Show the dialog
    final List<SelectableMedicine>? selected = await showDialog(
      context: context,
      builder: (ctx) => _MedicineSelectionDialog(
        medicines: allMedicines,
        previouslySelected: _suggestedMedicines,
      ),
    );

    if (selected != null) {
      setState(() {
        _suggestedMedicines = selected;
      });
    }
  }

  // Submits the response to Firestore
  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final inquiryRef = FirebaseFirestore.instance
          .collection('inquiries')
          .doc(widget.inquiryId);

      await inquiryRef.update({
        'status': 'responded',
        'response': {
          'responseText': _responseTextController.text.trim(),
          'suggestedMedicineIds': _suggestedMedicines
              .map((med) => med.id)
              .toList(),
          'responseTimestamp': FieldValue.serverTimestamp(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send response: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _responseTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiry Details'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('inquiries')
            .doc(widget.inquiryId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Inquiry not found or error loading.'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final formattedDate = timestamp != null
              ? DateFormat('d MMM yyyy, h:mm a').format(timestamp)
              : 'N/A';
          final isResponded = data['status'] == 'responded';

          // Pre-fill fields if already responded
          if (isResponded && _responseTextController.text.isEmpty) {
            _responseTextController.text =
                data['response']?['responseText'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard('From', data['userName'] ?? 'Unknown User'),
                  _buildInfoCard('Received', formattedDate),
                  const SizedBox(height: 16),
                  _buildSectionTitle('User\'s Symptoms'),
                  Text(
                    data['symptoms'] ?? 'No symptoms provided.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle('Your Response'),
                  TextFormField(
                    controller: _responseTextController,
                    readOnly: isResponded,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Provide your suggestion here...',
                      border: const OutlineInputBorder(),
                      filled: isResponded,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a response.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Suggested Medicines'),
                  _suggestedMedicines.isEmpty
                      ? const Text('No medicines suggested yet.')
                      : Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _suggestedMedicines
                              .map((med) => Chip(label: Text(med.name)))
                              .toList(),
                        ),
                  if (!isResponded)
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Suggest Medicines'),
                      onPressed: _showMedicineSelectorDialog,
                    ),
                  const SizedBox(height: 30),
                  if (!isResponded)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitResponse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Send Response',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}

// A stateful dialog to handle searching and selecting medicines
class _MedicineSelectionDialog extends StatefulWidget {
  final List<SelectableMedicine> medicines;
  final List<SelectableMedicine> previouslySelected;

  const _MedicineSelectionDialog({
    required this.medicines,
    required this.previouslySelected,
  });

  @override
  State<_MedicineSelectionDialog> createState() =>
      _MedicineSelectionDialogState();
}

class _MedicineSelectionDialogState extends State<_MedicineSelectionDialog> {
  late List<SelectableMedicine> _filteredMedicines;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mark previously selected items
    for (var med in widget.medicines) {
      if (widget.previouslySelected.any((pm) => pm.id == med.id)) {
        med.isSelected = true;
      }
    }
    _filteredMedicines = widget.medicines;
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedicines = widget.medicines
          .where((med) => med.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Medicines'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search your inventory...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMedicines.length,
                itemBuilder: (context, index) {
                  final med = _filteredMedicines[index];
                  return CheckboxListTile(
                    title: Text(med.name),
                    value: med.isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        med.isSelected = value ?? false;
                      });
                    },
                  );
                },
              ),
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
          onPressed: () {
            final selected = widget.medicines
                .where((m) => m.isSelected)
                .toList();
            Navigator.pop(context, selected);
          },
          child: const Text('Add Selected'),
        ),
      ],
    );
  }
}
