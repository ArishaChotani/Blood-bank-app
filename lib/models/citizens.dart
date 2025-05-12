import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/database_helper.dart';

class Citizen {
  String userName;
  final String _passwordHash; // Store only hashed passwords
  int age;
  String gender;
  double weight;
  String bloodGroup;
  double hb;
  int pulse;
  double systolicBP;
  double diastolicBP;

  Citizen({
    required this.userName,
    required String password, // Accept plaintext password but store hash
    this.age = 0,
    this.gender = '',
    this.weight = 0.0,
    this.bloodGroup = '',
    this.hb = 0.0,
    this.pulse = 0,
    this.systolicBP = 0.0,
    this.diastolicBP = 0.0,
  }) : _passwordHash = _hashPassword(password);

  // Secure password hashing using SHA-256
  static String _hashPassword(String plainText) {
    return sha256.convert(utf8.encode(plainText)).toString();
  }

  // Registration with validation
  static Future<bool> register(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw ArgumentError('Username and password cannot be empty');
    }

    if (username.contains(' ')) {
      throw ArgumentError('Username cannot contain spaces');
    }

    if (password.length < 8) {
      throw ArgumentError('Password must be at least 8 characters');
    }

    final db = await DatabaseHelper.instance.database;

    // Check if username exists
    final existingUser = await db.query(
      'citizens',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (existingUser.isNotEmpty) {
      return false; // Username exists
    }

    // Insert new citizen with hashed password
    await db.insert('citizens', {
      'username': username,
      'password_hash': _hashPassword(password),
      'age': 0,
      'gender': '',
      'weight': 0.0,
      'blood_group': '',
      'hb': 0.0,
      'pulse': 0,
      'systolic_bp': 0.0,
      'diastolic_bp': 0.0,
    });

    return true;
  }

  // Secure login with hash comparison
  static Future<bool> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'citizens',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, _hashPassword(password)],
    );

    return result.isNotEmpty;
  }

  // Get full citizen data after login
  static Future<Citizen?> getCitizen(String username) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'citizens',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isEmpty) return null;

    return Citizen(
      userName: result.first['username'] as String,
      password: result.first['password_hash'] as String, // This is the hash
      age: result.first['age'] as int,
      gender: result.first['gender'] as String,
      weight: result.first['weight'] as double,
      bloodGroup: result.first['blood_group'] as String,
      hb: result.first['hb'] as double,
      pulse: result.first['pulse'] as int,
      systolicBP: result.first['systolic_bp'] as double,
      diastolicBP: result.first['diastolic_bp'] as double,
    );
  }

  // Password update functionality
  static Future<bool> updatePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw ArgumentError('New password too short');
    }

    final db = await DatabaseHelper.instance.database;

    // Verify old password first
    final user = await db.query(
      'citizens',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, _hashPassword(oldPassword)],
    );

    if (user.isEmpty) {
      throw ArgumentError('Current password is incorrect or user not found');
    }

    // Update password
    await db.update(
      'citizens',
      {'password_hash': _hashPassword(newPassword)},
      where: 'username = ?',
      whereArgs: [username],
    );

    return true;
  }

  // Update citizen profile
  Future<bool> updateProfile() async {
    final db = await DatabaseHelper.instance.database;

    final updatedRows = await db.update(
      'citizens',
      {
        'age': age,
        'gender': gender,
        'weight': weight,
        'blood_group': bloodGroup,
        'hb': hb,
        'pulse': pulse,
        'systolic_bp': systolicBP,
        'diastolic_bp': diastolicBP,
      },
      where: 'username = ?',
      whereArgs: [userName],
    );

    return updatedRows > 0;
  }

  // Convert to map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'username': userName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'blood_group': bloodGroup,
      'hb': hb,
      'pulse': pulse,
      'systolic_bp': systolicBP,
      'diastolic_bp': diastolicBP,
    };
  }

  // Create from map (for JSON deserialization)
  factory Citizen.fromMap(Map<String, dynamic> map) {
    return Citizen(
      userName: map['username'],
      password: map['password_hash'], // This is the stored hash
      age: map['age'],
      gender: map['gender'],
      weight: map['weight'],
      bloodGroup: map['blood_group'],
      hb: map['hb'],
      pulse: map['pulse'],
      systolicBP: map['systolic_bp'],
      diastolicBP: map['diastolic_bp'],
    );
  }
}