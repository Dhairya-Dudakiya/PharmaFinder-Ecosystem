import 'package:flutter/material.dart';
import 'package:pharmafinder/models/medicine_model.dart';
import 'package:pharmafinder/utils/icon_helper.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const MedicineCard({Key? key, required this.medicine, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFFE8F5E9), // light green background
        elevation: 3,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                radius: 24,
                child: Icon(
                  getMedicineIcon(medicine.icon),
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                medicine.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.teal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₹${medicine.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                medicine.dosage,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                medicine.manufacturer,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: medicine.requiresPrescription
                      ? Colors.redAccent
                      : Colors.green.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  medicine.requiresPrescription ? 'Prescription' : 'No Rx',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
