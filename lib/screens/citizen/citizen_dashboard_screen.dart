import 'package:flutter/material.dart';
import '../donor/donate_blood_screen.dart';
import '../reciever/receive_blood_screen.dart';
import 'change_password_screen.dart'; // Import change password screen

class CitizenDashboardScreen extends StatelessWidget {
  final String username;

  const CitizenDashboardScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $username'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context); // Logout back
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildActionCard(
              context,
              Icons.bloodtype,
              'Donate Blood',
              Colors.red,
              'Help save lives by donating blood',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonateBloodScreen(username: username),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              Icons.medical_services,
              'Receive Blood',
              Colors.blue,
              'Request blood in times of need',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiveBloodScreen(username: username),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              Icons.settings,
              'Change Password',
              Colors.grey,
              'Update your account password',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(username: username),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context,
      IconData icon,
      String title,
      Color color,
      String subtitle,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
