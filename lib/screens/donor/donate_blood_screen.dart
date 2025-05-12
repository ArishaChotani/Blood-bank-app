import 'package:flutter/material.dart';
import '../../../models/donor.dart';
import '../../../models/blood.dart';
import '../../../models/validator.dart';
import '../../general/constants.dart';
import '../../services/database_helper.dart';

class DonateBloodScreen extends StatefulWidget {
  final String username;// Packets donated
  const DonateBloodScreen({super.key, required this.username});

  @override
  State<DonateBloodScreen> createState() => _DonateBloodScreenState();
}


class _DonateBloodScreenState extends State<DonateBloodScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Blood _blood = Blood();
  late Donor _donor; // Changed to late initialization
  int _packets = 1;
  bool _isSubmitting = false; // Added loading state
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _donor = Donor(userName: widget.username); //  use passed username
    await _blood.setPack();
  }


  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      _formKey.currentState!.save();

      // Set donor username manually before saving
      _donor.setName(widget.username);

      final bloodGroupIndex = _blood.updateInfo(_donor.bloodGroup);
      // NO need to call setPack() again here

      if (_blood.checkStorage(bloodGroupIndex, 'd', _packets)) {
        await Donor.saveDonor(_donor);
        await _saveDonorToDatabase();
        // No setPack here
        _blood.increment(_packets);
        await _blood.updateBloodReserves();

        _showSuccess();
      } else {
        _showError('Cannot donate blood. Storage check failed.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  void _showSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation submitted successfully')),
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Blood')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeField() => TextFormField(
    decoration: const InputDecoration(labelText: 'Age'),
    keyboardType: TextInputType.number,
    validator: Validator.validateAge,
    onSaved: (value) => _donor.setAge(int.parse(value ?? '0')),
  );

  Widget _buildGenderDropdown() => DropdownButtonFormField<String>(
    decoration: const InputDecoration(labelText: 'Gender'),
    items: ['Male', 'Female'].map((gender) => DropdownMenuItem(
      value: gender,
      child: Text(gender),
    )).toList(),
    validator: (value) => value == null ? 'Please select gender' : null,
    onChanged: (value) => _donor.setGen(value == 'Male' ? 'M' : 'F'),
  );

  Widget _buildWeightField() => TextFormField(
    decoration: const InputDecoration(labelText: 'Weight (kg)'),
    keyboardType: TextInputType.number,
    validator: Validator.validateWeight,
    onSaved: (value) => _donor.setWeight(double.parse(value ?? '0')),
  );

  Widget _buildBloodGroupDropdown() => DropdownButtonFormField<String>(
    decoration: const InputDecoration(labelText: 'Blood Group'),
    items: bloodGroups.map((group) => DropdownMenuItem(
      value: group,
      child: Text(group),
    )).toList(),
    validator: (value) => value == null ? 'Please select blood group' : null,
    onChanged: (value) => _donor.setBloodGroup(value ?? ''),
  );

  Widget _buildHemoglobinField() => TextFormField(
    decoration: const InputDecoration(labelText: 'Hemoglobin (g/dL)'),
    keyboardType: TextInputType.number,
    validator: Validator.validateHB,
    onSaved: (value) => _donor.setHB(double.parse(value ?? '0')),
  );

  Widget _buildPulseField() => TextFormField(
    decoration: const InputDecoration(labelText: 'Pulse Rate'),
    keyboardType: TextInputType.number,
    validator: Validator.validatePulse,
    onSaved: (value) => _donor.setPulse(int.parse(value ?? '0')),
  );

  Widget _buildSystolicBPField() => TextFormField(
    decoration: const InputDecoration(labelText: 'Systolic Blood Pressure'),
    keyboardType: TextInputType.number,
    validator: Validator.validateBP,
    onSaved: (value) => _donor.setSBP(double.parse(value ?? '0')),
  );

  Widget _buildDiastolicBPField() => TextFormField(
    decoration: const InputDecoration(labelText: 'Diastolic Blood Pressure'),
    keyboardType: TextInputType.number,
    validator: Validator.validateBP,
    onSaved: (value) => _donor.setDBP(double.parse(value ?? '0')),
  );

  Widget _buildPacketsDropdown() => DropdownButtonFormField<int>(
    decoration: const InputDecoration(labelText: 'Packets to Donate'),
    value: _packets,
    items: List.generate(5, (index) => index + 1)
        .map((count) => DropdownMenuItem(
      value: count,
      child: Text('$count'),
    )).toList(),
    onChanged: (value) => setState(() => _packets = value ?? 1),
  );

  Widget _buildSubmitButton() => ElevatedButton(
    onPressed: _isSubmitting ? null : _submitDonation,
    child: _isSubmitting
        ? const CircularProgressIndicator()
        : const Text('Submit Donation'),
  );

  Future<void> _saveDonorToDatabase() async {
    try {
      final db = await _dbHelper.database;
      await db.insert('donors', {
        'username': widget.username,
        'age': _donor.age,
        'gender': _donor.gender,
        'weight': _donor.weight,
        'blood_group': _donor.bloodGroup,
        'hb': _donor.hb,
        'pulse': _donor.pulse,
        'systolic_bp': _donor.systolicBP,
        'diastolic_bp': _donor.diastolicBP,
        'packets_donated': _packets,
        'donation_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _showError('Failed to save donor data: ${e.toString()}');
      rethrow;
    }
  }
}
