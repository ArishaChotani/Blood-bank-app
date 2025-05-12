// change_password_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String username;

  const ChangePasswordScreen({super.key, required this.username});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChanging = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChanging = true);

    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Get current user data
        final user = await txn.query(
          'citizens',
          where: 'username = ?',
          whereArgs: [widget.username],
          limit: 1,
        );

        if (user.isEmpty) {
          throw Exception('User not found');
        }

        // Verify old password
        final storedHash = user.first['password_hash'] as String;
        final oldPasswordHash = DatabaseHelper.getHashedPassword(_oldPasswordController.text);
        if (storedHash != oldPasswordHash) {
          throw Exception('Old password is incorrect');
        }

        // Update password
        final newPasswordHash = DatabaseHelper.getHashedPassword(_newPasswordController.text);
        await txn.update(
          'citizens',
          {'password_hash': newPasswordHash},
          where: 'username = ?',
          whereArgs: [widget.username],
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Old Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Enter old password'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter new password';
                  } else if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isChanging ? null : _changePassword,
                child: _isChanging
                    ? const CircularProgressIndicator()
                    : const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}