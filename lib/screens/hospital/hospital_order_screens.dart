import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class HospitalOrdersScreen extends StatefulWidget {
  const HospitalOrdersScreen({super.key});

  @override
  State<HospitalOrdersScreen> createState() => _HospitalOrdersScreenState();
}

class _HospitalOrdersScreenState extends State<HospitalOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('hospital_orders', orderBy: 'id DESC');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.local_hospital,
                    color: order['emergency'] == 1 ? Colors.red : Colors.green,
                  ),
                  title: Text(order['hospital_name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blood Group: ${order['blood_group']}'),
                      Text('Packets: ${order['packets']}'),
                      Text('Emergency: ${order['emergency'] == 1 ? 'Yes' : 'No'}'),
                      Text('Date: ${order['order_date']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}