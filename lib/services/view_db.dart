import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class DatabaseViewScreen extends StatefulWidget {
  const DatabaseViewScreen({super.key});

  @override
  _DatabaseViewScreenState createState() => _DatabaseViewScreenState();
}

class _DatabaseViewScreenState extends State<DatabaseViewScreen> {
  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    final db = await DatabaseHelper.instance.database;
    final hospitals = await db.query('hospitals'); // Fetch all hospitals from the database
    setState(() {
      _hospitals = hospitals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database View')),
      body: _hospitals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _hospitals.length,
        itemBuilder: (context, index) {
          final hospital = _hospitals[index];
          return ListTile(
            title: Text(hospital['name']),
            subtitle: Text(hospital['password']),
          );
        },
      ),
    );
  }
}
