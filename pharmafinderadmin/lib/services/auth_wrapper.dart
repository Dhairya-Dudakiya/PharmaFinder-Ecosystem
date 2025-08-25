// lib/screens/auth/auth_wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharmafinderadmin/screens/auth/login_screen.dart';
import 'package:pharmafinderadmin/screens/dashboard/admin_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for Firebase to respond, show a loading circle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If a user is logged in (snapshot has data), show the dashboard
        if (snapshot.hasData) {
          return const AdminDashboardScreen();
        }
        // Otherwise, show the login screen
        else {
          return const AdminLoginScreen();
        }
      },
    );
  }
}
