import 'package:firebase_database/firebase_database.dart';
import 'package:pharmafinder/models/medicine_model.dart';

class MedicineService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('medicines');

  // ✅ RENAMED: Changed to fetchAllMedicines to match the ViewModel
  Future<List<Medicine>> fetchAllMedicines() async {
    try {
      final snapshot = await _dbRef.get();
      final List<Medicine> medicines = [];

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Loop through stores
        data.forEach((storeName, medicinesMap) {
          if (medicinesMap is Map) {
            medicinesMap.forEach((id, medData) {
              try {
                // This logic is correct
                final medicine = Medicine.fromJson(
                  Map<String, dynamic>.from(medData),
                ).copyWith(id: id, storeName: storeName);
                medicines.add(medicine);
              } catch (e) {
                print("Error parsing medicine $id in store $storeName: $e");
              }
            });
          }
        });
      }

      return medicines;
    } catch (e) {
      throw Exception("Error fetching medicines: $e");
    }
  }

  // ✅ REMOVED: The fetchMedicinesByCategory method is no longer needed.
}
