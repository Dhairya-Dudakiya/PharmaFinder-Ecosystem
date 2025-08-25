// lib/screens/auth_screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmafinder/screens/main_screens/home_screen.dart';
import 'package:pharmafinder/screens/auth_screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Firebase automatically persists the user between sessions
    if (user != null) {
      return const HomeScreen(); // User is logged in
    } else {
      return const LoginScreen(); // Not logged in
    }
  }
}
