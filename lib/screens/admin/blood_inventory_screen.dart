import 'package:flutter/material.dart';
import '../../models/blood.dart';
// Ensure you have a database helper for SQLite

class BloodInventoryScreen extends StatefulWidget {
  const BloodInventoryScreen({super.key});

  @override
  State<BloodInventoryScreen> createState() => _BloodInventoryScreenState();
}

class _BloodInventoryScreenState extends State<BloodInventoryScreen> {
  final Blood _blood = Blood();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBloodData();
  }

  // Load blood data from the SQLite database
  Future<void> _loadBloodData() async {
    await _blood.setPack(); // Assuming setPack() loads from SQLite database
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the inventory of blood type in SQLite
  Future<void> _updateInventory(String bloodGroup, int newCount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final index = Blood.bloodGroups.indexOf(bloodGroup);
      if (index != -1) {
        // Update local state
        _blood.packets[index] = newCount;

        // Update database
        await _blood.updateBloodReserves();  // Make sure you have this method in your Blood model
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Inventory'),
        actions: [
          // Refresh button to reload data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBloodData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: Blood.bloodGroups.length,
        itemBuilder: (context, index) {
          final bloodGroup = Blood.bloodGroups[index];
          final count = _blood.packets[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.bloodtype, color: Colors.red),
              title: Text(bloodGroup),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _updateInventory(bloodGroup, count - 1),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _updateInventory(bloodGroup, count + 1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
