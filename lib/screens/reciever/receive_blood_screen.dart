import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/receiver.dart';
import '../../services/database_helper.dart';
import '../../services/transport_service.dart';
import '../../general/constants.dart';

class ReceiveBloodScreen extends StatefulWidget {
  final String username;
  const ReceiveBloodScreen({super.key, required this.username});

  @override
  State<ReceiveBloodScreen> createState() => _ReceiveBloodScreenState();
}

class _ReceiveBloodScreenState extends State<ReceiveBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final Receiver _receiver = Receiver();
  final TransportService _transport = TransportService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Form state variables
  int _packets = 1;
  bool _isSubmitting = false;
  bool _isEmergency = false;
  String _destination = 'Main Hospital';

  // Form controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _hbController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    // Initialize form with default values
    _ageController.text = '30';
    _weightController.text = '70';
    _hbController.text = '12.5';
    _pulseController.text = '72';
    _systolicBPController.text = '120';
    _diastolicBPController.text = '80';
    _selectedGender = 'Male';
    _selectedBloodGroup = 'O+';
  }

  @override
  void dispose() {
    // Clean up controllers
    _ageController.dispose();
    _weightController.dispose();
    _hbController.dispose();
    _pulseController.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Blood'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPressed,
        ),
      ),
      body: WillPopScope(
        onWillPop: _handleBackPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              children: [
                _buildNameField(),
                const SizedBox(height: 16),
                _buildAgeField(),
                const SizedBox(height: 16),
                _buildGenderDropdown(),
                const SizedBox(height: 16),
                _buildWeightField(),
                const SizedBox(height: 16),
                _buildBloodGroupDropdown(),
                const SizedBox(height: 16),
                _buildHemoglobinField(),
                const SizedBox(height: 16),
                _buildPulseField(),
                const SizedBox(height: 16),
                _buildSystolicBPField(),
                const SizedBox(height: 16),
                _buildDiastolicBPField(),
                const SizedBox(height: 16),
                _buildPacketsDropdown(),
                const SizedBox(height: 16),
                _buildEmergencyToggle(),
                const SizedBox(height: 16),
                _buildDestinationField(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBackPressed() async {
    if (_isSubmitting) return false;
        Navigator.pop(context);

    return false;
  }


  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Name'),
      initialValue: widget.username,
      enabled: false,
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      decoration: const InputDecoration(labelText: 'Age'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter age';
        final age = int.tryParse(value);
        if (age == null || age < 1 || age > 120) return 'Enter valid age (1-120)';
        return null;
      },
      onSaved: (value) => _receiver.setAge(int.parse(value ?? '0')),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(labelText: 'Gender'),
      items: ['Male', 'Female'].map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      )).toList(),
      validator: (value) => value == null ? 'Please select gender' : null,
      onChanged: (value) {
        setState(() => _selectedGender = value);
        _receiver.setGen(value == 'Male' ? 'M' : 'F');
      },
    );
  }


  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: const InputDecoration(labelText: 'Weight (kg)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter weight';
        final weight = double.tryParse(value);
        if (weight == null || weight < 20 || weight > 300) return 'Enter valid weight (20-300kg)';
        return null;
      },
      onSaved: (value) => _receiver.setWeight(double.parse(value ?? '0')),
    );
  }

  Widget _buildBloodGroupDropdown() {
    // Ensure bloodGroups list contains unique values
    final uniqueBloodGroups = bloodGroups.toSet().toList();

    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      decoration: const InputDecoration(labelText: 'Blood Group'),
      items: uniqueBloodGroups.map((group) => DropdownMenuItem<String>(
        value: group,
        child: Text(group),
      )).toList(),
      validator: (value) => value == null ? 'Please select blood group' : null,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedBloodGroup = value);
          _receiver.setBloodGroup(value);
        }
      },
    );
  }

  Widget _buildHemoglobinField() {
    return TextFormField(
      controller: _hbController,
      decoration: const InputDecoration(labelText: 'Hemoglobin (g/dL)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter hemoglobin';
        final hb = double.tryParse(value);
        if (hb == null || hb < 7 || hb > 20) return 'Enter valid hemoglobin (7-20 g/dL)';
        return null;
      },
      onSaved: (value) => _receiver.setHB(double.parse(value ?? '0')),
    );
  }

  Widget _buildPulseField() {
    return TextFormField(
      controller: _pulseController,
      decoration: const InputDecoration(labelText: 'Pulse Rate (bpm)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter pulse rate';
        final pulse = int.tryParse(value);
        if (pulse == null || pulse < 30 || pulse > 200) return 'Enter valid pulse (30-200 bpm)';
        return null;
      },
      onSaved: (value) => _receiver.setPulse(int.parse(value ?? '0')),
    );
  }

  Widget _buildSystolicBPField() {
    return TextFormField(
      controller: _systolicBPController,
      decoration: const InputDecoration(labelText: 'Systolic BP (mmHg)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter systolic BP';
        final sbp = double.tryParse(value);
        if (sbp == null || sbp < 80 || sbp > 200) return 'Enter valid systolic BP (80-200 mmHg)';
        return null;
      },
      onSaved: (value) => _receiver.setSBP(double.parse(value ?? '0')),
    );
  }

  Widget _buildDiastolicBPField() {
    return TextFormField(
      controller: _diastolicBPController,
      decoration: const InputDecoration(labelText: 'Diastolic BP (mmHg)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter diastolic BP';
        final dbp = double.tryParse(value);
        if (dbp == null || dbp < 50 || dbp > 120) return 'Enter valid diastolic BP (50-120 mmHg)';
        return null;
      },
      onSaved: (value) => _receiver.setDBP(double.parse(value ?? '0')),
    );
  }

  Widget _buildPacketsDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(labelText: 'Packets Needed'),
      value: _packets,
      validator: (value) {
        if (value == null || value <= 0) return 'Invalid packet count';
        if (value > 10) return 'Maximum 10 packets per request';
        return null;
      },
      items: List.generate(10, (index) => index + 1)
          .map((count) => DropdownMenuItem<int>(
        value: count,
        child: Text('$count'),
      )).toList(),
      onChanged: (value) => setState(() => _packets = value ?? 1),
    );
  }

  Widget _buildEmergencyToggle() {
    return SwitchListTile(
      title: const Text('Emergency Request'),
      value: _isEmergency,
      onChanged: (value) => setState(() => _isEmergency = value),
      secondary: Icon(
        _isEmergency ? Icons.warning : Icons.info,
        color: _isEmergency ? Colors.red : Colors.grey,
      ),
    );
  }

  Widget _buildDestinationField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Destination Hospital',
        hintText: 'Where blood should be delivered',
      ),
      initialValue: _destination,
      validator: (value) => value?.isEmpty ?? true ? 'Please enter destination' : null,
      onChanged: (value) => _destination = value,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _isSubmitting ? null : _handleSubmit,
      child: _isSubmitting
          ? const CircularProgressIndicator()
          : Text(
        _isEmergency ? 'EMERGENCY REQUEST' : 'Request Blood',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  void _handleSubmit() {
    // Force validation and show errors
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all errors before submitting'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    _submitRequest();
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    _receiver.updateLastReception();

    try {
      // Check blood availability
      final feasibility = await _transport.checkRequestFeasibility(
        _receiver.bloodGroup,
        _packets,
        emergency: _isEmergency,
      ).timeout(const Duration(seconds: 5));

      if (feasibility['canFulfill'] != true) {
        if (!mounted) return;
        _showInsufficientBloodDialog(feasibility);
        return;
      }

      // Process the request
      final result = await _transport.fulfillRequest(
        _receiver.bloodGroup,
        _packets,
        _destination,
        emergency: _isEmergency,
      ).timeout(const Duration(seconds: 5));

      if (result['success'] != true) {
        if (!mounted) return;
        _showError(result['reason'] ?? 'Failed to process request');
        return;
      }

      // Save receiver data
      await _saveReceiverToDatabase();

      if (!mounted) return;
      _showSuccess(result);
    } on TimeoutException catch (_) {
      _showError('Request timed out - please try again');
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveReceiverToDatabase() async {
    try {
      final db = await _dbHelper.database;
      await db.insert('receivers', {
        'username': widget.username,
        'age': _receiver.age,
        'gender': _receiver.gender,
        'weight': _receiver.weight,
        'blood_group': _receiver.bloodGroup,
        'hb': _receiver.hb,
        'pulse': _receiver.pulse,
        'systolic_bp': _receiver.systolicBP,
        'diastolic_bp': _receiver.diastolicBP,
        'last_reception_day': _receiver.lastReception.d,
        'last_reception_month': _receiver.lastReception.m,
        'last_reception_year': _receiver.lastReception.y,
        'packets_requested': _packets,
        'emergency': _isEmergency ? 1 : 0,
        'destination': _destination,
        'request_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _showError('Failed to save receiver data: ${e.toString()}');
      rethrow;
    }
  }

  void _showSuccess(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_isEmergency ? 'EMERGENCY REQUEST APPROVED' : 'Request Successful'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isEmergency ? Icons.warning : Icons.check_circle,
                color: _isEmergency ? Colors.orange : Colors.green,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(_isEmergency
                  ? 'Your request has been prioritized'
                  : 'Your blood request has been approved'),
              const SizedBox(height: 15),
              const Divider(),
              const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Blood Group: ${_receiver.bloodGroup}'),
              Text('• Packets: $_packets'),
              Text('• Destination: $_destination'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBloodDialog(Map<String, dynamic> feasibility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Blood Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requested: $_packets packets of ${_receiver.bloodGroup}'),
            Text('Available: ${feasibility['available']} compatible packets'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
