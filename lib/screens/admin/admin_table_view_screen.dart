import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class AdminTableViewScreen extends StatefulWidget {
  final String tableName;
  const AdminTableViewScreen({super.key, required this.tableName});

  @override
  State<AdminTableViewScreen> createState() => _AdminTableViewScreenState();
}

class _AdminTableViewScreenState extends State<AdminTableViewScreen> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _filteredRows = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTable();
  }

  Future<void> _loadTable() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final rows = await db.query(widget.tableName);
      setState(() {
        _rows = rows;
        _filteredRows = rows;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading table: $e')),
      );
    }
  }

  void _search(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredRows = _rows.where((row) {
        return row.values.any((value) =>
            value.toString().toLowerCase().contains(_searchQuery));
      }).toList();
    });
  }

  Future<void> _deleteRow(int id) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.delete(
        widget.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      _loadTable();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting record: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.tableName} Data')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredRows.isEmpty
                ? const Center(child: Text('No data found'))
                : ListView.builder(
              itemCount: _filteredRows.length,
              itemBuilder: (context, index) {
                final row = _filteredRows[index];
                return Card(
                  child: ListTile(
                    title: Text(row.toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (row['id'] != null) {
                          _deleteRow(row['id']);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
