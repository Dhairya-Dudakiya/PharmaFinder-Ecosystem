// services/pharmacy_service.dart
import 'package:pharmafinder/models/pharmacy_model.dart';

class PharmacyService {
  Future<List<Pharmacy>> getNearbyPharmacies() async {
    // In a real app, this would fetch data from Firebase/Firestore
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      Pharmacy(
        id: '1',
        name: 'Green Valley Pharmacy',
        address: '123 Main St, City Center',
        distance: 1.2,
        rating: 4.7,
        reviewCount: 124,
        deliveryTime: 25,
        isOpen: true,
        phone: '+1 (555) 123-4567',
        services: ['Delivery', 'Pickup', '24/7'],
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Pharmacy(
        id: '2',
        name: 'MediCare Pharmacy',
        address: '456 Oak Ave, West District',
        distance: 2.5,
        rating: 4.5,
        reviewCount: 89,
        deliveryTime: 35,
        isOpen: true,
        phone: '+1 (555) 987-6543',
        services: ['Delivery', 'Consultation'],
      ),
      Pharmacy(
        id: '3',
        name: 'City Health Pharmacy',
        address: '789 Pine Rd, East Side',
        distance: 3.1,
        rating: 4.9,
        reviewCount: 210,
        deliveryTime: 45,
        isOpen: false,
        phone: '+1 (555) 456-7890',
        services: ['Pickup', 'Emergency'],
      ),
    ];
  }
}
