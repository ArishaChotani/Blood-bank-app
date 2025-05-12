import 'package:flutter/material.dart';
import 'admin/admin_login_screen.dart';
import 'citizen/citizen_screen.dart';
import 'hospital/hospital_login_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Bank'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuButton(context, 'Admin Portal', Icons.admin_panel_settings, Colors.red, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
              }),
              const SizedBox(height: 20),
              _buildMenuButton(context, 'Citizen Portal', Icons.person, Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CitizenScreen()));
              }),
              const SizedBox(height: 20),
              _buildMenuButton(context, 'Hospital Portal', Icons.local_hospital, Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HospitalLoginScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 60),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
