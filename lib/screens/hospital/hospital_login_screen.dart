import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import 'hospital_dashboard_screen.dart';
import "hospital_register_screen.dart";
import '../../general/logo.dart';

class HospitalLoginScreen extends StatefulWidget {
  const HospitalLoginScreen({super.key});

  @override
  _HospitalLoginScreenState createState() => _HospitalLoginScreenState();
}

class _HospitalLoginScreenState extends State<HospitalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'hospitals',
      where: 'name = ? AND password_hash = ? AND status = ?',
      whereArgs: [
        _nameController.text.trim(),
        DatabaseHelper.getHashedPassword(_passwordController.text.trim()),
        'approved'
      ],
    );

    if (result.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HospitalDashboardScreen(
            hospitalName: _nameController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials or account not approved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const BloodLogo(size: 100),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Hospital Name',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hospital name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              // Add the Register button here
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HospitalRegistrationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, // You can change the color here
                ),
                child: const Text('Register Hospital'),
              ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Back to Main Menu',
              style: TextStyle(fontSize: 14),
            ),
          )
            ],
          ),
        ),
      ),
    );
  }
}