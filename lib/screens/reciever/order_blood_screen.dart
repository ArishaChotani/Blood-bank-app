import 'package:flutter/material.dart';
import '../../general/constants.dart';
import '../../services/database_helper.dart';
import '../../services/transport_service.dart';

class OrderBloodScreen extends StatefulWidget {
  final String hospitalName;

  const OrderBloodScreen({super.key, required this.hospitalName});

  @override
  _OrderBloodScreenState createState() => _OrderBloodScreenState();
}

class _OrderBloodScreenState extends State<OrderBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransportService _transportService = TransportService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  String _bloodGroup = bloodGroups.first;
  int _packets = 1;
  bool _emergency = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Blood')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Blood Group'),
                value: _bloodGroup,
                items: bloodGroups.map((group) => DropdownMenuItem(
                  value: group,
                  child: Text(group),
                )).toList(),
                validator: (value) => value == null ? 'Please select blood group' : null,
                onChanged: (value) => setState(() => _bloodGroup = value ?? ''),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Packets Needed'),
                value: _packets,
                items: List.generate(5, (index) => index + 1).map((count) => DropdownMenuItem(
                  value: count,
                  child: Text('$count'),
                )).toList(),
                onChanged: (value) => setState(() => _packets = value ?? 1),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Emergency Order'),
                value: _emergency,
                onChanged: (value) => setState(() => _emergency = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // 1. Try to fulfill the request using transport service
        final result = await _transportService.fulfillRequest(
          _bloodGroup,
          _packets,
          widget.hospitalName,
          emergency: _emergency,
        );

        if (result['success']) {
          // 2. Save order to SQLite database
          final now = DateTime.now();
          await _databaseHelper.database.then((db) async {
            await db.insert('hospital_orders', {
              'hospital_name': widget.hospitalName,
              'blood_group': _bloodGroup,
              'packets': _packets,
              'emergency': _emergency ? 1 : 0,
              'order_date': now.toIso8601String(),
            });

            // Update blood inventory (deduct the ordered packets)
            final currentInventory = await db.query(
              'blood_inventory',
              where: 'blood_group = ?',
              whereArgs: [_bloodGroup],
            );

            if (currentInventory.isNotEmpty) {
              final currentPackets = currentInventory.first['packets'] as int;
              await db.update(
                'blood_inventory',
                {'packets': currentPackets - _packets},
                where: 'blood_group = ?',
                whereArgs: [_bloodGroup],
              );
            }
          });

          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blood order placed and dispatched successfully!')),
          );
        } else {
          _showError(result['reason'] ?? 'Unable to place order');
        }
      } catch (e) {
        _showError('Failed to place order: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}