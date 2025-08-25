import 'package:flutter/material.dart';
import 'package:pharmafinder/utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            title: 'Account Settings',
            items: [
              _buildSettingsItem(Icons.notifications, 'Notification Settings'),
              _buildSettingsItem(Icons.privacy_tip, 'Privacy & Security'),
              _buildSettingsItem(Icons.language, 'Language'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'Preferences',
            items: [
              _buildSettingsItem(Icons.location_on, 'Location Services'),
              _buildSettingsItem(Icons.medication, 'Medicine Preferences'),
              _buildSettingsItem(Icons.accessibility, 'Accessibility'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'Support',
            items: [
              _buildSettingsItem(Icons.help, 'Help Center'),
              _buildSettingsItem(Icons.feedback, 'Send Feedback'),
              _buildSettingsItem(Icons.description, 'Terms & Policies'),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.update),
              label: const Text('Check for Updates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme().primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A7B79)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
