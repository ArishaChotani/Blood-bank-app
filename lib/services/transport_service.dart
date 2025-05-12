import '../models/blood.dart';
import 'database_helper.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum VehicleStatus { available, assigned, maintenance, inTransit }
enum TransportStatus { dispatched, inProgress, delivered, cancelled }

class BloodPacket {
  final String group;
  final int taken;
  final int remaining;

  BloodPacket({
    required this.group,
    required this.taken,
    required this.remaining,
  });

  Map<String, dynamic> toMap() {
    return {
      'group': group,
      'taken': taken,
      'remaining': remaining,
    };
  }
}

class TransportLog {
  final String id;
  final DateTime timestamp;
  final String receiverGroup;
  final String destination;
  final String vehicleId;
  final String branchId;
  final TransportStatus status;
  final bool emergency;

  TransportLog({
    required this.id,
    required this.timestamp,
    required this.receiverGroup,
    required this.destination,
    required this.vehicleId,
    required this.branchId,
    required this.status,
    required this.emergency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'receiver_group': receiverGroup,
      'destination': destination,
      'vehicle_id': vehicleId,
      'branch_id': branchId,
      'status': _enumToString(status),
      'emergency': emergency ? 1 : 0,
    };
  }

  String _enumToString(TransportStatus status) {
    return status.toString().split('.').last;
  }
}

class TransportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Blood _blood = Blood();

  static const _compatibilityMap = {
    'O-': ['O-'],
    'O+': ['O-', 'O+'],
    'A-': ['O-', 'A-'],
    'A+': ['O-', 'O+', 'A-', 'A+'],
    'B-': ['O-', 'B-'],
    'B+': ['O-', 'O+', 'B-', 'B+'],
    'AB-': ['O-', 'A-', 'B-', 'AB-'],
    'AB+': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
  };

  Future<List<Map<String, dynamic>>> getAvailableVehicles(int requiredCapacity) async {
    final db = await _dbHelper.database;
    return await db.query('vehicles',
        where: 'status = ? AND capacity >= ?',
        whereArgs: [_enumToString(VehicleStatus.available), requiredCapacity],
        //orderBy: 'capacity ASC' // Get smallest suitable vehicle first
    );
  }

  Future<Map<String, dynamic>> findAndAssignVehicle({
    required int packets,
    required String destination,
    bool emergency = false,
  }) async {
    try {
      // 1. Find suitable vehicles
      final vehicles = await getAvailableVehicles(packets);

      if (vehicles.isEmpty && emergency) {
        // Emergency fallback - find any available vehicle regardless of capacity
        final db = await _dbHelper.database;
        final emergencyVehicle = await db.query('vehicles',
            where: 'status = ?',
            whereArgs: [_enumToString(VehicleStatus.available)],
            orderBy: 'capacity DESC',
            limit: 1
        );

        if (emergencyVehicle.isNotEmpty) {
          return await assignVehicle(
            vehicleId: emergencyVehicle.first['id'] as String,
            destination: destination,
            packets: packets,
          );
        }
      }

      if (vehicles.isNotEmpty) {
        return await assignVehicle(
          vehicleId: vehicles.first['id'] as String,
          destination: destination,
          packets: packets,
        );
      }

      return {
        'success': false,
        'reason': 'No available vehicles matching requirements'
      };
    } catch (e) {
      return {
        'success': false,
        'reason': 'Vehicle search failed: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> assignVehicle({
    required String vehicleId,
    required String destination,
    required int packets,
  }) async {
    final db = await _dbHelper.database;
    await db.execute('BEGIN TRANSACTION');

    try {
      // 1. Verify vehicle is still available
      final vehicle = await db.query('vehicles',
          where: 'id = ? AND status = ?',
          whereArgs: [vehicleId, _enumToString(VehicleStatus.available)],
          limit: 1
      );

      if (vehicle.isEmpty) {
        return {
          'success': false,
          'reason': 'Vehicle no longer available'
        };
      }

      // 2. Update vehicle status
      await db.update('vehicles',
          {
            'status': _enumToString(VehicleStatus.assigned),
            'last_used': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [vehicleId]
      );

      return {
        'success': true,
        'vehicleId': vehicle.first['id'] as String,
        'branchId': vehicle.first['branch_id'] as String,
        'details': {
          'vehicleType': vehicle.first['type'],
          'capacity': vehicle.first['capacity'],
          'estimatedArrival': '2 hours', // Default estimate
        },
      };
    } catch (e) {
      await db.execute('ROLLBACK');
      return {
        'success': false,
        'reason': 'Assignment failed: ${e.toString()}'
      };
    }
  }

  Future<void> completeTransport(String transportId) async {
    final db = await _dbHelper.database;
    await db.execute('BEGIN TRANSACTION');

    try {
      // 1. Get transport record
      final transport = await db.query('transport_logs',
          where: 'id = ?',
          whereArgs: [transportId],
          limit: 1
      );

      if (transport.isNotEmpty) {
        // 2. Update vehicle status
        await db.update('vehicles',
            {'status': _enumToString(VehicleStatus.available)},
            where: 'id = ?',
            whereArgs: [transport.first['vehicle_id']]
        );

        // 3. Update transport log
        await db.update('transport_logs',
            {
              'status': _enumToString(TransportStatus.delivered),
              'completion_time': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [transportId]
        );
      }

      await db.execute('COMMIT');
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  // ========== ENHANCED BLOOD MANAGEMENT ==========

  Future<Map<String, dynamic>> checkRequestFeasibility(
      String receiverGroup,
      int requestedPackets, {
        bool emergency = false,
      }) async {
    try {
      final db = await _dbHelper.database;
      receiverGroup = receiverGroup.toUpperCase().trim();

      final inventory = await db.query(
          'blood_inventory',
          where: 'packets > 0'
      );

      debugPrint('Raw Inventory: $inventory');

      int available = 0;
      final compatibleGroups = <String, int>{};

      if (receiverGroup == 'AB+') {
        available = inventory.fold(0, (sum, item) {
          final packets = (item['packets'] as int?) ?? 0;
          final group = (item['blood_group'] as String?).toString().toUpperCase();
          compatibleGroups[group] = packets;
          return sum + packets;
        });
      } else {
        for (final item in inventory) {
          final group = (item['blood_group'] as String?).toString().toUpperCase();
          final packets = (item['packets'] as int?) ?? 0;

          if (isCompatible(receiverGroup, group)) {
            available += packets;
            compatibleGroups[group] = packets;
          }
        }
      }

      debugPrint('''
      Feasibility Check:
      - Receiver: $receiverGroup
      - Requested: $requestedPackets
      - Available: $available
      - Compatible Groups: $compatibleGroups
      - Emergency: $emergency
      ''');

      return {
        'canFulfill': available >= requestedPackets,
        'available': available,
        'needed': requestedPackets,
        'receiverGroup': receiverGroup,
        'compatibleGroups': compatibleGroups,
        'emergency': emergency,
      };
    } catch (e, stackTrace) {
      debugPrint('Feasibility check error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'canFulfill': false,
        'error': 'System error: ${e.toString()}',
        'available': 0,
        'needed': requestedPackets,
      };
    }
  }

  // ========== CORE REQUEST PROCESSING ==========

  Future<Map<String, dynamic>> fulfillRequest(
      String receiverGroup,
      int packetsNeeded,
      String destination, {
        bool emergency = false,
      }) async {
    final db = await _dbHelper.database;
    await db.execute('BEGIN TRANSACTION');

    try {
      // 1. Verify blood availability
      final bloodCheck = await _checkBloodAvailability(receiverGroup, packetsNeeded, emergency);
      if (!bloodCheck['hasEnoughBlood']) {
        await db.execute('ROLLBACK');
        return {
          'success': false,
          'reason': 'Insufficient blood available',
          'available': bloodCheck['available'],
        };
      }

      // 2. Allocate blood packets
      final allocationResult = await _allocateBloodPackets(receiverGroup, packetsNeeded, emergency);
      if (!allocationResult['success']) {
        await db.execute('ROLLBACK');
        return allocationResult;
      }

      // 3. Assign vehicle using improved logic
      final vehicleResult = await findAndAssignVehicle(
        packets: packetsNeeded,
        destination: destination,
        emergency: emergency,
      );

      if (!vehicleResult['success']) {
        await _returnBloodPackets(allocationResult['usedPackets']);
        await db.execute('ROLLBACK');
        return {
          'success': false,
          'reason': vehicleResult['reason'],
          'vehicleAvailable': false,
        };
      }

      // 4. Create transport log
      final logId = 'TR${DateTime.now().millisecondsSinceEpoch}';
      final log = TransportLog(
        id: logId,
        timestamp: DateTime.now(),
        receiverGroup: receiverGroup,
        destination: destination,
        vehicleId: vehicleResult['vehicleId'],
        branchId: vehicleResult['branchId'],
        status: TransportStatus.dispatched,
        emergency: emergency,
      );

      await db.insert('transport_logs', log.toMap());
      await _blood.updateBloodReserves();
      await db.execute('COMMIT');

      return {
        'success': true,
        'logId': logId,
        'vehicleId': vehicleResult['vehicleId'],
        'usedPackets': allocationResult['usedPackets'],
        'transportDetails': vehicleResult['details'],
      };
    } catch (e) {
      await db.execute('ROLLBACK');
      debugPrint('Transport Error: $e');
      return {
        'success': false,
        'reason': 'Transaction failed: ${e.toString()}',
      };
    }
  }

  // ========== HELPER METHODS ==========

  bool isCompatible(String receiverGroup, String donorGroup, {bool emergency = false}) {
    if (emergency && donorGroup == 'O-') return true;
    return _compatibilityMap[receiverGroup]?.contains(donorGroup) ?? false;
  }

  Future<Map<String, dynamic>> _checkBloodAvailability(
      String receiverGroup,
      int requestedPackets,
      bool emergency,
      ) async {
    final db = await _dbHelper.database;
    final inventory = await db.query('blood_inventory');
    int available = 0;
    final compatibleGroups = <String, int>{};

    for (final item in inventory) {
      final group = item['blood_group'] as String;
      final packets = item['packets'] as int;

      if (isCompatible(receiverGroup, group, emergency: emergency)) {
        available += packets;
        compatibleGroups[group] = packets;
      }
    }

    return {
      'hasEnoughBlood': available >= requestedPackets,
      'available': available,
      'compatibleGroups': compatibleGroups,
    };
  }

  Future<Map<String, dynamic>> _allocateBloodPackets(
      String receiverGroup,
      int packetsNeeded,
      bool emergency,
      ) async {
    final db = await _dbHelper.database;
    final usedPackets = <BloodPacket>[];
    int remaining = packetsNeeded;

    final inventory = await db.query('blood_inventory');
    for (final item in inventory) {
      if (remaining <= 0) break;

      final group = item['blood_group'] as String;
      final currentPackets = item['packets'] as int;

      if (isCompatible(receiverGroup, group, emergency: emergency) && currentPackets > 0) {
        final taken = min(currentPackets, remaining);
        remaining -= taken;
        final newCount = currentPackets - taken;

        await db.update(
          'blood_inventory',
          {'packets': newCount},
          where: 'blood_group = ?',
          whereArgs: [group],
        );

        usedPackets.add(BloodPacket(
          group: group,
          taken: taken,
          remaining: newCount,
        ));
      }
    }

    if (remaining > 0) {
      return {
        'success': false,
        'reason': 'Could only allocate ${packetsNeeded - remaining} of $packetsNeeded packets',
      };
    }

    return {
      'success': true,
      'usedPackets': usedPackets,
    };
  }

  Future<void> _returnBloodPackets(List<BloodPacket> usedPackets) async {
    final db = await _dbHelper.database;
    for (final packet in usedPackets) {
      await db.rawUpdate('''
        UPDATE blood_inventory 
        SET packets = packets + ? 
        WHERE blood_group = ?
      ''', [packet.taken, packet.group]);
    }
  }

  // ========== UTILITY METHODS ==========

  String _enumToString(dynamic enumValue) {
    return enumValue.toString().split('.').last;
  }

  TransportStatus _parseTransportStatus(String status) {
    return TransportStatus.values.firstWhere(
          (e) => e.toString() == 'TransportStatus.$status',
      orElse: () => TransportStatus.dispatched,
    );
  }

  Future<List<TransportLog>> getTransportHistory() async {
    try {
      final db = await _dbHelper.database;
      final logs = await db.query('transport_logs');
      return logs.map((log) => TransportLog(
        id: log['id'] as String,
        timestamp: DateTime.parse(log['timestamp'] as String),
        receiverGroup: log['receiver_group'] as String,
        destination: log['destination'] as String,
        vehicleId: log['vehicle_id'] as String,
        branchId: log['branch_id'] as String,
        status: _parseTransportStatus(log['status'] as String),
        emergency: (log['emergency'] as int) == 1,
      )).toList();
    } catch (e) {
      debugPrint('Error getting transport history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNearestBranch(double lat, double lng) async {
    try {
      final db = await _dbHelper.database;
      final branches = await db.query('branches');
      return branches.isNotEmpty ? branches.first : {'error': 'No branches available'};
    } catch (e) {
      debugPrint('Error getting nearest branch: $e');
      return {'error': e.toString()};
    }
  }
}