import '../services/database_helper.dart';
import 'date.dart';

class Receiver {
  String userName;
  int age;
  String gender;
  double weight;
  String bloodGroup;
  double hb;
  int pulse;
  double systolicBP;
  double diastolicBP;
  Date lastReception;

  Receiver({
    this.userName = '',
    this.age = 0,
    this.gender = '',
    this.weight = 0.0,
    this.bloodGroup = '',
    this.hb = 0.0,
    this.pulse = 0,
    this.systolicBP = 0.0,
    this.diastolicBP = 0.0,
    Date? lastReception,
  }) : lastReception = lastReception ?? Date();

  // Setter methods
  void setAge(int newAge) => age = newAge;
  void setGen(String newGender) => gender = newGender;
  void setWeight(double newWeight) => weight = newWeight;
  void setPulse(int newPulse) => pulse = newPulse;
  void setHB(double newHb) => hb = newHb;
  void setSBP(double newSbp) => systolicBP = newSbp;
  void setDBP(double newDbp) => diastolicBP = newDbp;
  void setBloodGroup(String newBloodGroup) => bloodGroup = newBloodGroup;
  void setName(String name) => userName = name;

  // Getter methods
  String getName() => userName;
  Date getLastReception() => lastReception;
  void setLastReception(Date d) => lastReception = d;

  void updateLastReception() {
    final now = DateTime.now();
    lastReception.setDate(now.day);
    lastReception.setMonth(now.month);
    lastReception.setYear(now.year);
  }

  // Save receiver to database
  static Future<void> saveReceiver(Receiver receiver) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('receivers', {
      'username': receiver.userName,
      'age': receiver.age,
      'gender': receiver.gender,
      'weight': receiver.weight,
      'blood_group': receiver.bloodGroup,
      'hb': receiver.hb,
      'pulse': receiver.pulse,
      'systolic_bp': receiver.systolicBP,
      'diastolic_bp': receiver.diastolicBP,
      'last_reception_day': receiver.lastReception.d,
      'last_reception_month': receiver.lastReception.m,
      'last_reception_year': receiver.lastReception.y,
    });
  }

  // Get all receivers from database
  static Future<List<Receiver>> getAllReceivers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('receivers');

    return maps.map((map) => Receiver(
      userName: map['username'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      weight: map['weight'] as double,
      bloodGroup: map['blood_group'] as String,
      hb: map['hb'] as double,
      pulse: map['pulse'] as int,
      systolicBP: map['systolic_bp'] as double,
      diastolicBP: map['diastolic_bp'] as double,
      lastReception: Date(
        map['last_reception_day'] as int,
        map['last_reception_month'] as int,
        map['last_reception_year'] as int,
      ),
    )).toList();
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'username': userName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'bloodGroup': bloodGroup,
      'hb': hb,
      'pulse': pulse,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'lastReception': lastReception.toMap(),
    };
  }

  // Create from Map (for JSON deserialization)
  factory Receiver.fromMap(Map<String, dynamic> map) {
    return Receiver(
      userName: map['username'],
      age: map['age'],
      gender: map['gender'],
      weight: map['weight'],
      bloodGroup: map['bloodGroup'],
      hb: map['hb'],
      pulse: map['pulse'],
      systolicBP: map['systolicBP'],
      diastolicBP: map['diastolicBP'],
      lastReception: Date.fromMap(map['lastReception']),
    );
  }
}