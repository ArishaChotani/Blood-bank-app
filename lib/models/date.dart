class Date {
  int d = 0, m = 0, y = 0;
  static const List<int> monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  Date([this.d = 0, this.m = 0, this.y = 0]);

  void setDate(int day) => d = day;
  void setMonth(int month) => m = month;
  void setYear(int year) => y = year;

  int countLeapYears(Date d) {
    int years = d.y;
    if (d.m <= 2) years--;
    return (years ~/ 4) - (years ~/ 100) + (years ~/ 400);
  }

  int getDifference(Date dt1, Date dt2) {
    int n1 = dt1.y * 365 + dt1.d;
    for (int i = 0; i < dt1.m - 1; i++) {
      n1 += monthDays[i];
    }
    n1 += countLeapYears(dt1);

    int n2 = dt2.y * 365 + dt2.d;
    for (int i = 0; i < dt2.m - 1; i++) {
      n2 += monthDays[i];
    }
    n2 += countLeapYears(dt2);

    return (n2 - n1);
  }

  @override
  String toString() {
    return "$d/$m/$y";
  }

  // For parsing from strings
  factory Date.fromString(String dateStr) {
    final parts = dateStr.split('/');
    return Date(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Convert to Map for database storage
  Map<String, int> toMap() {
    return {
      'day': d,
      'month': m,
      'year': y,
    };
  }

  // Create from Map (for database retrieval)
  factory Date.fromMap(Map<String, dynamic> map) {
    return Date(
      map['day'] as int,
      map['month'] as int,
      map['year'] as int,
    );
  }
}