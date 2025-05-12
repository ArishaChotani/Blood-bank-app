import 'package:flutter/material.dart';
import '../../models/receiver.dart';

class ReceiverListScreen extends StatefulWidget {
  const ReceiverListScreen({super.key});

  @override
  State<ReceiverListScreen> createState() => _ReceiverListScreenState();
}

class _ReceiverListScreenState extends State<ReceiverListScreen> {
  late Future<List<Receiver>> _receiversFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceivers();
  }

  Future<void> _loadReceivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final receivers = await Receiver.getAllReceivers();
      _receiversFuture = Future.value(receivers);
    } catch (e) {
      debugPrint('Error loading receivers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load receivers: $e')),
      );
      _receiversFuture = Future.value([]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivers List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceivers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Receiver>>(
        future: _receiversFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No receivers found'));
          }

          return _buildReceiverList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildReceiverList(List<Receiver> receivers) {
    return ListView.builder(
      itemCount: receivers.length,
      itemBuilder: (context, index) {
        final receiver = receivers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.blue),
            title: Text(
              receiver.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${receiver.bloodGroup} • ${receiver.age} yrs • ${receiver.gender}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReceiverDetails(context, receiver),
          ),
        );
      },
    );
  }

  void _showReceiverDetails(BuildContext context, Receiver receiver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(receiver.userName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Age', '${receiver.age} years'),
              _buildDetailRow('Gender', receiver.gender),
              _buildDetailRow('Weight', '${receiver.weight} kg'),
              _buildDetailRow('Blood Group', receiver.bloodGroup),
              _buildDetailRow('Hemoglobin', '${receiver.hb} g/dL'),
              _buildDetailRow('Pulse Rate', '${receiver.pulse} bpm'),
              _buildDetailRow(
                'Blood Pressure',
                '${receiver.systolicBP}/${receiver.diastolicBP} mmHg',
              ),
              _buildDetailRow(
                'Last Reception',
                '${receiver.lastReception.d}/${receiver.lastReception.m}/${receiver.lastReception.y}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}