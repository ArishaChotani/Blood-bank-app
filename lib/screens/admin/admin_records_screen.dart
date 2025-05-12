import 'package:flutter/material.dart';
import '../../../models/donor.dart';
import '../../../models/receiver.dart';

class AdminRecordSearchScreen extends StatefulWidget {
  const AdminRecordSearchScreen({super.key});

  @override
  State<AdminRecordSearchScreen> createState() => _AdminRecordSearchScreenState();
}

class _AdminRecordSearchScreenState extends State<AdminRecordSearchScreen> {
  List<Donor> _allDonors = [];
  List<Receiver> _allReceivers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final donors = await Donor.getAllDonors();
    final receivers = await Receiver.getAllReceivers();
    setState(() {
      _allDonors = donors;
      _allReceivers = receivers;
    });
  }

  List<Map<String, dynamic>> _getFilteredResults() {
    final filtered = <Map<String, dynamic>>[];

    for (final donor in _allDonors) {
      if (donor.userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        filtered.add({'type': 'Donor', 'record': donor});
      }
    }

    for (final receiver in _allReceivers) {
      if (receiver.userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        filtered.add({'type': 'Receiver', 'record': receiver});
      }
    }

    return filtered;
  }

  void _showDetails(dynamic record, String type) {
    showDialog(
      context: context,
      builder: (context) {
        final details = type == 'Donor'
            ? _donorDetails(record as Donor)
            : _receiverDetails(record as Receiver);

        return AlertDialog(
          title: Text('$type: ${record.userName}'),
          content: details,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _donorDetails(Donor d) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Age: ${d.age}'),
      Text('Gender: ${d.gender}'),
      Text('Weight: ${d.weight} kg'),
      Text('Blood Group: ${d.bloodGroup}'),
      Text('Hemoglobin: ${d.hb} g/dL'),
      Text('Pulse: ${d.pulse} bpm'),
      Text('BP: ${d.systolicBP}/${d.diastolicBP} mmHg'),
      Text('Last Donation: ${d.lastDonate.d}/${d.lastDonate.m}/${d.lastDonate.y}'),
    ],
  );

  Widget _receiverDetails(Receiver r) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Age: ${r.age}'),
      Text('Gender: ${r.gender}'),
      Text('Weight: ${r.weight} kg'),
      Text('Blood Group: ${r.bloodGroup}'),
      Text('Hemoglobin: ${r.hb} g/dL'),
      Text('Pulse: ${r.pulse} bpm'),
      Text('BP: ${r.systolicBP}/${r.diastolicBP} mmHg'),
      Text('Last Reception: ${r.lastReception.d}/${r.lastReception.m}/${r.lastReception.y}'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final results = _getFilteredResults();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Search Records')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search donors or receivers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No matching records found.'))
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final record = result['record'];
                final type = result['type'];
                final icon = type == 'Donor'
                    ? Icons.bloodtype
                    : Icons.medical_services;

                return ListTile(
                  leading: Icon(icon, color: type == 'Donor' ? Colors.red : Colors.blue),
                  title: Text(record.userName),
                  subtitle: Text('Type: $type — Blood Group: ${record.bloodGroup}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showDetails(record, type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
