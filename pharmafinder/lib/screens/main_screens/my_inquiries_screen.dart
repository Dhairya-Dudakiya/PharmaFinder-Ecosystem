import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pharmafinder/screens/main_screens/inquiry_response_screen.dart';

class MyInquiriesScreen extends StatelessWidget {
  const MyInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your inquiries.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inquiries'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query for inquiries that belong to the current user
        stream: FirebaseFirestore.instance
            .collection('inquiries')
            .where('userId', isEqualTo: user.uid)
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
            return const Center(
              child: Text(
                'You have not submitted any inquiries yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final inquiries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: inquiries.length,
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              final data = inquiry.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedDate = timestamp != null
                  ? DateFormat('d MMM yyyy, h:mm a').format(timestamp)
                  : 'No date';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    'Inquiry from $formattedDate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['symptoms'] ?? 'No symptoms provided',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: status == 'pending'
                        ? Colors.orange
                        : Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onTap: () {
                    // Navigate to the detail screen to see the response
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InquiryResponseScreen(inquiryId: inquiry.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
