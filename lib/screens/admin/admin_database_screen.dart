import 'package:flutter/material.dart';
import 'admin_table_view_screen.dart';

class AdminDatabaseScreen extends StatelessWidget {
  const AdminDatabaseScreen({super.key});

  final List<String> tables = const [
    'citizens',
    'donors',
    'receivers',
    'hospitals',
    'blood_inventory',
    'hospital_orders',
    'vehicles',
    'branches',
    'transport_logs',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Database View')),
      body: ListView.builder(
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final tableName = tables[index];
          return Card(
            child: ListTile(
              title: Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminTableViewScreen(tableName: tableName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
