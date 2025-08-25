import 'package:flutter/material.dart';
import 'package:pharmafinder/utils/constants.dart';
import 'package:pharmafinder/widgets/app_bar.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildActiveReservations(),
                  _buildCompletedReservations(),
                  _buildCancelledReservations(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveReservations() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ReservationCard(
          status: 'Pending',
          pharmacyName: 'Green Valley Pharmacy',
          medicineName: 'Paracetamol 500mg',
          date: 'Today, 3:30 PM',
          color: Colors.orange,
        ),
        ReservationCard(
          status: 'Ready for Pickup',
          pharmacyName: 'MediCare Pharmacy',
          medicineName: 'Ibuprofen 200mg',
          date: 'Today, 4:00 PM',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildCompletedReservations() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ReservationCard(
          status: 'Completed',
          pharmacyName: 'City Health Pharmacy',
          medicineName: 'Vitamin C 1000mg',
          date: 'June 15, 2023',
          color: Colors.blue,
        ),
        ReservationCard(
          status: 'Completed',
          pharmacyName: 'Green Valley Pharmacy',
          medicineName: 'Aspirin 75mg',
          date: 'June 10, 2023',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildCancelledReservations() {
    return const Center(child: Text('No cancelled reservations'));
  }
}

class ReservationCard extends StatelessWidget {
  final String status;
  final String pharmacyName;
  final String medicineName;
  final String date;
  final Color color;

  const ReservationCard({
    super.key,
    required this.status,
    required this.pharmacyName,
    required this.medicineName,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(date, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              pharmacyName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(medicineName, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 16),
                if (status == 'Pending' || status == 'Ready for Pickup')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        status == 'Ready for Pickup' ? 'Pick Up' : 'Cancel',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
