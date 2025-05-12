
import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';
import 'app_theme.dart';
import '../../services/database_helper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // Initialize database
  runApp(const BloodBankApp());
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Donation Bank',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}