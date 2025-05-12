class Validator {
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter age';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0) {
      return 'Please enter a valid age';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name';
    }
    final name = int.tryParse(value);
    if (name == null) {
      return 'Please enter a valid name';
    }
    return null;
  }
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter weight';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight';
    }
    if (weight < 45) {
      return 'Minimum weight is 45 kg';
    }
    return null;
  }

  static String? validateHB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter hemoglobin level';
    }
    final hb = double.tryParse(value);
    if (hb == null || hb <= 0) {
      return 'Please enter a valid hemoglobin level';
    }
    return null;
  }

  static String? validatePulse(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter pulse rate';
    }
    final pulse = int.tryParse(value);
    if (pulse == null || pulse <= 0) {
      return 'Please enter a valid pulse rate';
    }
    if (pulse < 50 || pulse > 100) {
      return 'Pulse should be between 50-100 bpm';
    }
    return null;
  }

  static String? validateBP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter blood pressure';
    }
    final bp = double.tryParse(value);
    if (bp == null || bp <= 0) {
      return 'Please enter a valid blood pressure';
    }
    return null;
  }
}