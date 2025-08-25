// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharmafinderadmin/screens/dashboard/splash_screen.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PharmaFinderAdminApp());
}

class PharmaFinderAdminApp extends StatelessWidget {
  const PharmaFinderAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmaFinder Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),

      // ✅ 2. SET the SplashScreen as the home screen
      home: const SplashScreen(),

      routes: {
        '/login': (context) => const AdminLoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
