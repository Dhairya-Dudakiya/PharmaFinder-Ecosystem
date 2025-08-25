import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pharmafinderadmin/screens/dashboard/InquiryDetailScreen.dart';

class InquiryListScreen extends StatelessWidget {
  const InquiryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Pending and Responded
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Symptom Inquiries',
            style: TextStyle(color: Colors.white), // Improved UI
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white, // Makes back arrow white
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Responded'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white, // Improved UI
          ),
        ),
        body: TabBarView(
          children: [
            _buildInquiryList(context, 'pending'),
            _buildInquiryList(context, 'responded'),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryList(BuildContext context, String status) {
    // Use a StreamBuilder to get real-time updates from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inquiries')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status inquiries found.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final inquiries = snapshot.data!.docs;

        return ListView.builder(
          itemCount: inquiries.length,
          itemBuilder: (context, index) {
            final inquiry = inquiries[index];
            final data = inquiry.data() as Map<String, dynamic>;

            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final formattedDate = timestamp != null
                ? DateFormat('d MMM yyyy, h:mm a').format(timestamp)
                : 'No date';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'pending'
                      ? Colors.orange.shade100
                      : Colors.teal.shade100,
                  child: Icon(
                    status == 'pending'
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle_outline_rounded,
                    color: status == 'pending'
                        ? Colors.orange.shade800
                        : Colors.teal,
                  ),
                ),
                title: Text(
                  data['userName'] ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['symptoms'] ?? 'No symptoms provided',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                // ✅ FIX: Navigation is now enabled.
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InquiryDetailScreen(inquiryId: inquiry.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
