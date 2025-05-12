/*import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class FileStorageService {
  static Future<String> get _localPath async {
    final directory = 'C:\Users\HP\StudioProjects\blood_bank_app\data';
    return directory;
  }

  static Future<File> getLocalFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  static Future<void> initFiles() async {
    try {
      final defaultFiles = {
        'Blood.txt': '0\n0\n0\n0\n0\n0\n0\n0', // Initial blood units
        'Citizen.txt': '',
        'Donor.txt': '',
        'Receiver.txt': '',
        'Hospital.txt': '',
        'HospitalOrders.txt': ''
      };

      for (final entry in defaultFiles.entries) {
        final file = await getLocalFile(entry.key);
        if (!await file.exists() || (await file.readAsString()).isEmpty) {
          await file.writeAsString(entry.value);
          debugPrint('Initialized ${entry.key}');
        }
      }
    } catch (e) {
      debugPrint('Error initializing files: $e');
    }
  }

  static Future<List<String>> readLines(String filename) async {
    try {
      final file = await getLocalFile(filename);
      if (!await file.exists()) {
        debugPrint('$filename does not exist');
        return [];
      }
      final content = await file.readAsString();
      return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error reading $filename: $e');
      return [];
    }
  }

  static Future<void> writeLines(String filename, List<String> lines) async {
    try {
      final file = await getLocalFile(filename);
      await file.writeAsString(lines.join('\n'));
      debugPrint('Updated $filename with ${lines.length} entries');
    } catch (e) {
      debugPrint('Error writing to $filename: $e');
      rethrow;
    }
  }

  static Future<void> appendLine(String filename, String line) async {
    try {
      final file = await getLocalFile(filename);
      await file.writeAsString('$line\n', mode: FileMode.append);
      debugPrint('Appended to $filename: $line');
    } catch (e) {
      debugPrint('Error appending to $filename: $e');
      rethrow;
    }
  }
}*/