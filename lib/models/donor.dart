import '../services/database_helper.dart';
import 'date.dart';

class Donor {
  String userName;
  int age;
  String gender;
  double weight;
  String bloodGroup;
  double hb;
  int pulse;
  double systolicBP;
  double diastolicBP;
  Date lastDonate;

  Donor({
    required this.userName,
    this.age = 0,
    this.gender = '',
    this.weight = 0.0,
    this.bloodGroup = '',
    this.hb = 0.0,
    this.pulse = 0,
    this.systolicBP = 0.0,
    this.diastolicBP = 0.0,
    Date? lastDonate,
  }) : lastDonate = lastDonate ?? Date();

  // Setter methods
  void setAge(int newAge) => age = newAge;

  void setGen(String newGender) => gender = newGender;

  void setWeight(double newWeight) => weight = newWeight;

  void setBloodGroup(String newBloodGroup) => bloodGroup = newBloodGroup;

  void setHB(double newHb) => hb = newHb;

  void setPulse(int newPulse) => pulse = newPulse;

  void setSBP(double newSBP) => systolicBP = newSBP;

  void setDBP(double newDBP) => diastolicBP = newDBP;

  void setLastDonate(Date date) => lastDonate = date;

  void setName(String name) => userName = name;

  // Save donor to database
  static Future<void> saveDonor(Donor donor) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('donors', {
      'username': donor.userName,
      'age': donor.age,
      'gender': donor.gender,
      'weight': donor.weight,
      'blood_group': donor.bloodGroup,
      'hb': donor.hb,
      'pulse': donor.pulse,
      'systolic_bp': donor.systolicBP,
      'diastolic_bp': donor.diastolicBP,

    });
  }

  // Get all donors from database
  static Future<List<Donor>> getAllDonors() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('donors');

    return maps.map((map) =>
        Donor(
          userName: map['username'] as String,
          age: map['age'] as int,
          gender: map['gender'] as String,
          weight: map['weight'] as double,
          bloodGroup: map['blood_group'] as String,
          hb: map['hb'] as double,
          pulse: map['pulse'] as int,
          systolicBP: map['systolic_bp'] as double,
          diastolicBP: map['diastolic_bp'] as double,
          lastDonate: Date(
            map['last_donate_day'] as int,
            map['last_donate_month'] as int,
            map['last_donate_year'] as int,
          ),
        )).toList();
  }
}
