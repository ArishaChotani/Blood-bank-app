import 'package:flutter/material.dart';
import 'citizen_dashboard_screen.dart';
import '../../services/database_helper.dart';
import '../../general/logo.dart';

class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  _CitizenLoginScreenState createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _validateCredentials(String username, String password) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'citizens',
        where: 'username = ? COLLATE NOCASE', // Case-insensitive comparison
        whereArgs: [username.trim()], // Trim whitespace
        limit: 1,
      );

      if (result.isNotEmpty) {
        final storedHash = result.first['password_hash'] as String;
        final inputHash = DatabaseHelper.getHashedPassword(password.trim());
        return storedHash == inputHash;
      }
      return false;
    } catch (e) {
      debugPrint('Error validating credentials: $e');
      return false;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final isValid = await _validateCredentials(username, password);

      if (!mounted) return;
      if (isValid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CitizenDashboardScreen(
              username: username,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const BloodLogo(size: 100),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
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
                onPressed: _isLoggingIn ? null : _login,
                child: _isLoggingIn
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: _isLoggingIn ? null : () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}