import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class HospitalRegistrationScreen extends StatefulWidget {
  const HospitalRegistrationScreen({super.key});

  @override
  State<HospitalRegistrationScreen> createState() => _HospitalRegistrationScreenState();
}

class _HospitalRegistrationScreenState extends State<HospitalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      final db = await DatabaseHelper.instance.database;

      // Check if hospital exists
      final existing = await db.query(
        'hospitals',
        where: 'name = ?',
        whereArgs: [_nameController.text.trim()],
      );

      if (existing.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hospital already registered')),
        );
        return;
      }

      // Register new hospital
      await db.insert('hospitals', {
        'name': _nameController.text.trim(),
        'password_hash': DatabaseHelper.getHashedPassword(_passwordController.text.trim()),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted for approval')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Hospital')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                  if (value.contains(' ')) {
                    return 'Hospital name cannot contain spaces';
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
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                child: _isRegistering
                    ? const CircularProgressIndicator()
                    : const Text('Register Hospital'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}