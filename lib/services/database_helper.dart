import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'transport_service.dart';

class DatabaseHelper {
  static const _databaseName = 'bloodbank.db';
  static const _databaseVersion = 3;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _initializeBloodInventory(db);
    await _addSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE transport_logs (
          id TEXT PRIMARY KEY,
          timestamp TEXT NOT NULL,
          receiver_group TEXT NOT NULL,
          destination TEXT NOT NULL,
          vehicle_id TEXT NOT NULL,
          branch_id TEXT NOT NULL,
          status TEXT NOT NULL,
          emergency INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE vehicles (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          capacity INTEGER NOT NULL,
          branch_id TEXT NOT NULL,
          status TEXT NOT NULL,
          last_maintenance TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE branches (
          id TEXT PRIMARY KEY,
          city TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          contact TEXT NOT NULL,
          vehicles INTEGER NOT NULL,
          staff INTEGER NOT NULL,
          capacity INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE citizens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        age INTEGER DEFAULT 0,
        gender TEXT DEFAULT '',
        weight REAL DEFAULT 0.0,
        blood_group TEXT DEFAULT '',
        hb REAL DEFAULT 0.0,
        pulse INTEGER DEFAULT 0,
        systolic_bp REAL DEFAULT 0.0,
        diastolic_bp REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE donors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        age INTEGER DEFAULT 0,
        gender TEXT DEFAULT '',
        weight REAL DEFAULT 0.0,
        blood_group TEXT DEFAULT '',
        hb REAL DEFAULT 0.0,
        pulse INTEGER DEFAULT 0,
        systolic_bp REAL DEFAULT 0.0,
        diastolic_bp REAL DEFAULT 0.0,
        last_donate_day INTEGER DEFAULT 0,
        last_donate_month INTEGER DEFAULT 0,
        last_donate_year INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE receivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        age INTEGER DEFAULT 0,
        gender TEXT DEFAULT '',
        weight REAL DEFAULT 0.0,
        blood_group TEXT DEFAULT '',
        hb REAL DEFAULT 0.0,
        pulse INTEGER DEFAULT 0,
        systolic_bp REAL DEFAULT 0.0,
        diastolic_bp REAL DEFAULT 0.0,
        last_reception_day INTEGER DEFAULT 0,
        last_reception_month INTEGER DEFAULT 0,
        last_reception_year INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE hospitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        address TEXT DEFAULT '',
        contact TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        emergency_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE blood_inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        blood_group TEXT UNIQUE NOT NULL,
        packets INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE hospital_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_name TEXT NOT NULL,
        blood_group TEXT NOT NULL,
        packets INTEGER NOT NULL,
        emergency INTEGER NOT NULL,
        order_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        branch_id TEXT NOT NULL,
        status TEXT NOT NULL,
        last_maintenance TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE branches (
        id TEXT PRIMARY KEY,
        city TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        contact TEXT NOT NULL,
        vehicles INTEGER NOT NULL,
        staff INTEGER NOT NULL,
        capacity INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _initializeBloodInventory(Database db) async {
    const bloodGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
    final batch = db.batch();

    for (final group in bloodGroups) {
      batch.insert('blood_inventory', {
        'blood_group': group,
        'packets': 0
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit();
  }

  Future<void> _addSampleData(Database db) async {
    // Add admin citizen
    await db.insert('citizens', {
      'username': 'arisha',
      'password_hash': _hashPassword('123'),
      'age': 22,
      'gender': 'Male',
      'weight': 75.0,
      'blood_group': 'O+',
      'hb': 14.5,
      'pulse': 72,
      'systolic_bp': 120.0,
      'diastolic_bp': 80.0
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Fixed: Changed 'password' to 'password_hash' and added required fields
    await db.insert('hospitals', {
      'name': 'City General Hospital',
      'password_hash': _hashPassword('hospital123'),
      'address': '123 Main Street',
      'contact': '1234567890',
      'status': 'approved'
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Add sample blood inventory
    await db.update(
      'blood_inventory',
      {'packets': 15},
      where: 'blood_group = ?',
      whereArgs: ['O+'],
    );

    // Add sample branch
    await db.insert('branches', {
      'id': 'BR001',
      'city': 'Multan',
      'latitude': 30.3308,
      'longitude': 71.2475,
      'contact': '+923001234567',
      'vehicles': 3,
      'staff': 5,
      'capacity': 1000,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Add sample vehicle
    await db.insert('vehicles', {
      'id': 'VH001',
      'type': 'Refrigerated Van',
      'capacity': 20,
      'branch_id': 'BR001',
      'status': 'available',
      'last_maintenance': DateTime(2023, 1, 15).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static String _hashPassword(String plainText) {
    return sha256.convert(utf8.encode(plainText)).toString();
  }

  static String getHashedPassword(String plainText) {
    return _hashPassword(plainText);
  }

  Future<void> updateHospitalEmergencyStatus(String name, bool emergency) async {
    final db = await database;
    await db.update(
      'hospitals',
      {'emergency_status': emergency ? 1 : 0},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<List<Map<String, dynamic>>> getAvailableVehicles() async {
    final db = await database;
    return await db.query('vehicles',
        where: "status = ?",
        whereArgs: ['available']
    );
  }



  Future<int> updateTransportLog(TransportLog log) async {
    final db = await database;
    return await db.insert('transport_logs', {
      'id': log.id,
      'timestamp': log.timestamp.toIso8601String(),
      'receiver_group': log.receiverGroup,
      'destination': log.destination,
      'vehicle_id': log.vehicleId,
      'branch_id': log.branchId,
      'status': log.status.toString().split('.').last,
      'emergency': log.emergency ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getTransportLogs() async {
    final db = await database;
    return await db.query('transport_logs');
  }

  static Future<void> printTableContents(String tableName) async {
    final db = await instance.database;
    final data = await db.query(tableName);
    debugPrint('Contents of $tableName:');
    for (final row in data) {
      debugPrint(row.toString());
    }
  }

 /* Future<void> resetDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _databaseName);

    if (_database != null) {
      await _database!.close();  // Close existing connection
      _database = null;          // Clear cached instance
    }

    await deleteDatabase(path);  // Delete the database file
    _database = await _initDatabase();  // Reinitialize
  }*/

}