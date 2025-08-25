import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pharmafinder/models/medicine_model.dart';
import 'package:pharmafinder/screens/main_screens/medicine_detail_screen.dart';

class InquiryResponseScreen extends StatelessWidget {
  final String inquiryId;
  const InquiryResponseScreen({super.key, required this.inquiryId});

  // Helper function to fetch details for a list of medicine IDs
  Future<List<Medicine>> _fetchSuggestedMedicines(List<dynamic> ids) async {
    if (ids.isEmpty) return [];

    final List<Medicine> medicines = [];
    final dbRef = FirebaseDatabase.instance.ref('medicines');

    // This is a simplified fetch. For production, you might want to optimize
    // by fetching from specific stores if that info is available.
    final snapshot = await dbRef.get();
    if (snapshot.exists && snapshot.value is Map) {
      final allStores = Map<String, dynamic>.from(snapshot.value as Map);
      for (var storeName in allStores.keys) {
        final inventory = Map<String, dynamic>.from(
          allStores[storeName] as Map,
        );
        for (var medId in ids) {
          if (inventory.containsKey(medId)) {
            final medData = Map<String, dynamic>.from(inventory[medId] as Map);
            medData['id'] = medId;
            medData['storeName'] = storeName;
            medicines.add(Medicine.fromJson(medData));
          }
        }
      }
    }
    return medicines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacist Response'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('inquiries')
            .doc(inquiryId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Inquiry not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final responseData = data['response'] as Map<String, dynamic>?;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSection(
                title: 'Your Symptoms',
                content: Text(
                  data['symptoms'] ?? 'N/A',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const Divider(height: 30),
              _buildSection(
                title: 'Pharmacist\'s Suggestion',
                content: responseData == null
                    ? const Text(
                        'The pharmacist has not responded yet.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    : Text(
                        responseData['responseText'] ?? 'No text response.',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
              ),
              if (responseData != null &&
                  responseData['suggestedMedicineIds'] != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Suggested Medicines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<Medicine>>(
                  future: _fetchSuggestedMedicines(
                    responseData['suggestedMedicineIds'],
                  ),
                  builder: (context, medSnapshot) {
                    if (medSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!medSnapshot.hasData || medSnapshot.data!.isEmpty) {
                      return const Text('Could not load suggested medicines.');
                    }
                    return Column(
                      children: medSnapshot.data!
                          .map(
                            (med) => Card(
                              child: ListTile(
                                title: Text(med.name),
                                subtitle: Text(
                                  med.storeName ?? 'Unknown Store',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MedicineDetailScreen(medicine: med),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}
