import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_helper.dart';

class HospitalApprovalScreen extends StatefulWidget {
  const HospitalApprovalScreen({super.key});

  @override
  State<HospitalApprovalScreen> createState() => _HospitalApprovalScreenState();
}

class _HospitalApprovalScreenState extends State<HospitalApprovalScreen> {
  List<Map<String, dynamic>> _pendingHospitals = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verifyAdminStatus().then((_) => _loadPendingHospitals());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('isAdmin') ?? false;
    });
  }

  Future<void> _approveHospital(int index) async {
    if (!_isAdmin) {
      _showAdminRestriction();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      final hospital = _pendingHospitals[index];

      await db.update(
        'hospitals',
        {
          'status': 'approved',
          'emergency_status': 0,
        },
        where: 'id = ?',
        whereArgs: [hospital['id']],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hospital approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadPendingHospitals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving hospital: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectHospital(int index) async {
    if (!_isAdmin) {
      _showAdminRestriction();
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject this hospital?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmDelete) return;

    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      final hospital = _pendingHospitals[index];

      await db.delete(
        'hospitals',
        where: 'id = ?',
        whereArgs: [hospital['id']],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hospital rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      await _loadPendingHospitals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting hospital: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAdminRestriction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin privileges required'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _loadPendingHospitals() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      final hospitals = await db.query(
        'hospitals',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at DESC',
      );

      setState(() {
        _pendingHospitals = hospitals;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading hospitals: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewHospital() async {
    if (!_isAdmin) {
      _showAdminRestriction();
      return;
    }

    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final addressController = TextEditingController();
    final contactController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Hospital'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Hospital Name',
                  hintText: 'Enter hospital name',
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Set login password',
                ),
                obscureText: true,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter hospital address',
                ),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  hintText: 'Enter contact number',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and password are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final db = await _dbHelper.database;
                await db.insert('hospitals', {
                  'name': nameController.text,
                  'password_hash': DatabaseHelper.getHashedPassword(passwordController.text),
                  'address': addressController.text,
                  'contact': contactController.text,
                  'status': 'pending',
                  'emergency_status': 0,
                  'created_at': DateTime.now().toIso8601String(),
                });

                if (!mounted) return;
                Navigator.of(context).pop();
                await _loadPendingHospitals();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding hospital: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredHospitals {
    if (_searchController.text.isEmpty) {
      return _pendingHospitals;
    }
    return _pendingHospitals.where((hospital) {
      final name = hospital['name'].toString().toLowerCase();
      return name.contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Approvals'),
        actions: [
          if (_pendingHospitals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPendingHospitals,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search hospitals',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHospitals.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No pending hospital approvals'
                        : 'No matching hospitals found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredHospitals.length,
              itemBuilder: (context, index) {
                final hospital = _filteredHospitals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text(
                      hospital['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Registered: ${_formatDate(hospital['created_at'])}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Address:', hospital['address']),
                            _buildDetailRow('Contact:', hospital['contact']),
                            _buildDetailRow('Status:', hospital['status']),
                            if (_isAdmin) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _rejectHospital(
                                        _pendingHospitals.indexWhere(
                                                (h) => h['id'] == hospital['id'])),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _approveHospital(
                                        _pendingHospitals.indexWhere(
                                                (h) => h['id'] == hospital['id'])),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Approve',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        onPressed: _addNewHospital,
        tooltip: 'Add Hospital',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not provided',
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}