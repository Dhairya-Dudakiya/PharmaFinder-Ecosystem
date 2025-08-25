import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SymptomInquiryScreen extends StatefulWidget {
  const SymptomInquiryScreen({super.key});

  @override
  State<SymptomInquiryScreen> createState() => _SymptomInquiryScreenState();
}

class _SymptomInquiryScreenState extends State<SymptomInquiryScreen> {
  final _symptomsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit an inquiry.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Fetch user's name from their profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous User';

      // Save the inquiry to the top-level 'inquiries' collection
      await FirebaseFirestore.instance.collection('inquiries').add({
        'userId': user.uid,
        'userName': userName,
        'symptoms': _symptomsController.text.trim(),
        'status': 'pending', // Initial status
        'timestamp': FieldValue.serverTimestamp(),
        'response': null, // No response yet
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your inquiry has been submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit inquiry: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Pharmacist'),
        backgroundColor: Colors.teal,
        // ✅ This line makes both the title text and back arrow white
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe Your Symptoms',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide as much detail as possible for a better suggestion. Our pharmacist will review your inquiry and respond shortly.',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _symptomsController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText:
                      'e.g., "I have a mild headache, a runny nose, and have been sneezing since yesterday morning."',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your symptoms.';
                  }
                  if (value.length < 10) {
                    return 'Please provide more detail (at least 10 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildDisclaimer(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitInquiry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Inquiry',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade800,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Disclaimer: The suggestions provided are for general guidance only and are not a substitute for a professional medical diagnosis. Please consult a doctor for serious conditions.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
