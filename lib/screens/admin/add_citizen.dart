import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../services/database_helper.dart';

class AddCitizenScreen extends StatefulWidget {
  const AddCitizenScreen({super.key});

  @override
  State<AddCitizenScreen> createState() => _AddCitizenScreenState();
}

class _AddCitizenScreenState extends State<AddCitizenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _addCitizen() async {
    if (_formKey.currentState!.validate()) {
      final db = await DatabaseHelper.instance.database;

      // Insert citizen data into the database
      await db.insert(
        'citizens',
        {
          'username': _usernameController.text.trim(), // Added trim()
          'password_hash': DatabaseHelper.getHashedPassword(_passwordController.text), // Fixed hashing
          'age': 0, // Added default values
          'gender': '',
          'weight': 0.0,
          'blood_group': '',
          'hb': 0.0,
          'pulse': 0,
          'systolic_bp': 0.0,
          'diastolic_bp': 0.0
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Citizen added successfully')),
      );

      _usernameController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Citizen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addCitizen,
                child: const Text('Add Citizen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}