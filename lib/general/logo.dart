// Create this widget once (e.g., in components/logo.dart)
import 'package:flutter/material.dart';

class BloodLogo extends StatelessWidget {
  final double size;

  const BloodLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.bloodtype,
      size: size,
      color: Colors.red, // Match your splash screen
    );
  }
}