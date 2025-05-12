import 'package:flutter/material.dart';
import '../reciever/order_blood_screen.dart';
import '../../services/database_helper.dart';

class HospitalDashboardScreen extends StatefulWidget {
  final String hospitalName;

  const HospitalDashboardScreen({super.key, required this.hospitalName});

  @override
  _HospitalDashboardScreenState createState() =>
      _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  bool _emergencyStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hospitalName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Emergency Status'),
              subtitle: Text(_emergencyStatus ? 'ON' : 'OFF'),
              value: _emergencyStatus,
              onChanged: (value) async {
                setState(() => _emergencyStatus = value);
                await DatabaseHelper.instance.updateHospitalEmergencyStatus(
                  widget.hospitalName,
                  value,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Emergency status ${value ? 'activated' : 'deactivated'}')),
                );
              },
              secondary: Icon(
                Icons.warning,
                color: _emergencyStatus ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrderBloodScreen(hospitalName: widget.hospitalName),
                  ),
                );
              },
              child: const Text('Order Blood'),
            ),
          ],
        ),
      ),
    );
  }
}
