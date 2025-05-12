import 'package:flutter/material.dart';
import '../../models/donor.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  late Future<List<Donor>> _donorsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final donors = await Donor.getAllDonors();
      _donorsFuture = Future.value(donors);
    } catch (e) {
      debugPrint('Error loading donors: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load donors: $e')),
      );
      _donorsFuture = Future.value([]);
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
        title: const Text('Donors List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDonors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Donor>>(
        future: _donorsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No donors found'));
          }

          return _buildDonorList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDonorList(List<Donor> donors) {
    return ListView.builder(
      itemCount: donors.length,
      itemBuilder: (context, index) {
        final donor = donors[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.bloodtype, color: Colors.red),
            title: Text(donor.userName),
            subtitle: Text('Blood Group: ${donor.bloodGroup}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showDonorDetails(context, donor),
          ),
        );
      },
    );
  }

  void _showDonorDetails(BuildContext context, Donor donor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donor.userName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Age', donor.age.toString()),
              _buildDetailRow('Gender', donor.gender),
              _buildDetailRow('Weight', '${donor.weight} kg'),
              _buildDetailRow('Blood Group', donor.bloodGroup),
              _buildDetailRow('Hemoglobin', '${donor.hb} g/dL'),
              _buildDetailRow('Pulse', '${donor.pulse} bpm'),
              _buildDetailRow('Blood Pressure',
                  '${donor.systolicBP}/${donor.diastolicBP} mmHg'),
              _buildDetailRow('Last Donation',
                  '${donor.lastDonate.d}/${donor.lastDonate.m}/${donor.lastDonate.y}'),
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
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}