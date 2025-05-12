import '../services/database_helper.dart';

class Blood {
  List<int> packets = [0, 0, 0, 0, 0, 0, 0, 0];
  int updateIndex = 0;
  int updatePacks = 0;
  String updateGroup = "";

  static const List<String> bloodGroups = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-',
  ];

  Future<void> setPack() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('blood_inventory', orderBy: 'id');
    packets = maps.map((map) => map['packets'] as int).toList();
  }

  int updateInfo(String bloodgrp) {
    updateGroup = bloodgrp;
    updateIndex = bloodGroups.indexOf(bloodgrp);
    return updateIndex;
  }

  bool checkStorage(int tempIndex, String mode, int packs) {
    if (mode == 'r') {
      // Receiving blood, check if enough stock available
      return packets[tempIndex] >= packs;
    } else if (mode == 'd') {
      // Donating blood, no limit (can always donate)
      return true;
    }
    return false;
  }

  bool confirmRequest() {
    return updateIndex != -1;
  }

  Future<void> updateBloodReserves() async {
    final db = await DatabaseHelper.instance.database;
    for (int i = 0; i < packets.length; i++) {
      await db.update(
        'blood_inventory',
        {'packets': packets[i]},
        where: 'blood_group = ?',
        whereArgs: [bloodGroups[i]],
      );
    }
  }

  void increment(int packetsCount) {
    packets[updateIndex] += packetsCount;
  }

  void decrement(int packetsCount) {
    packets[updateIndex] -= packetsCount;
  }

  static bool isCompatible(String receiverGroup, String donorGroup) {
    const compatibilityMap = {
      'O-': ['O-'],
      'O+': ['O-', 'O+'],
      'A-': ['O-', 'A-'],
      'A+': ['O-', 'O+', 'A-', 'A+'],
      'B-': ['O-', 'B-'],
      'B+': ['O-', 'O+', 'B-', 'B+'],
      'AB-': ['O-', 'A-', 'B-', 'AB-'],
      'AB+': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
    };

    return compatibilityMap[receiverGroup]?.contains(donorGroup) ?? false;
  }
}