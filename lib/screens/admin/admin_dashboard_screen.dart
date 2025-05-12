import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../donor/donor_list_screen.dart';
import '../reciever/receiver_list_screen.dart';
import 'blood_inventory_screen.dart';
import 'admin_records_screen.dart';
import '../hospital/hospital_order_screens.dart';
import '../hospital/hospital_approval_screen.dart';
import 'admin_database_screen.dart';
import 'add_citizen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final bool isAdmin;
  const AdminDashboardScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardItem(
              context,
              Icons.person_add,
              'Add Citizen',
              Colors.teal,
                  () => _navigateTo(context, const AddCitizenScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.people,
              'Donors List',
              Colors.blue,
                  () => _navigateTo(context, const DonorListScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.medical_services,
              'Receivers List',
              Colors.green,
                  () => _navigateTo(context, const ReceiverListScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.storage,
              'View Database',
              Colors.deepPurple,
                  () => _navigateTo(context, const AdminDatabaseScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.bloodtype,
              'Blood Inventory',
              Colors.red,
                  () => _navigateTo(context, const BloodInventoryScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.search,
              'Search Records',
              Colors.orange,
                  () => _navigateTo(context, const AdminRecordSearchScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.local_hospital,
              'Hospital Orders',
              Colors.purple,
                  () => _navigateTo(context, const HospitalOrdersScreen()),
            ),
            _buildDashboardItem(
              context,
              Icons.verified_user,
              'Hospital Approvals',
              Colors.deepPurple,
                  () {
                if (isAdmin) {
                  _navigateTo(context, const HospitalApprovalScreen());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin privileges required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
      BuildContext context,
      IconData icon,
      String title,
      Color color,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAdmin');
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}