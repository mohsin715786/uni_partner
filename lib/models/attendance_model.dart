class AttendanceCourse {
  final String id;
  final String? courseId;
  final String courseName;
  int attendedClasses;
  int totalClasses;

  static const double requiredAttendance = 75.0;

  AttendanceCourse({
    required this.id,
    this.courseId,
    required this.courseName,
    this.attendedClasses = 0,
    this.totalClasses = 0,
  });

  /// Calculates current attendance percentage (0 to 100).
  double get attendancePercentage {
    if (totalClasses == 0) return 0.0;
    return (attendedClasses / totalClasses) * 100.0;
  }

  /// Marks the student as Present for a class.
  void markPresent() {
    attendedClasses++;
    totalClasses++;
  }

  /// Marks the student as Absent for a class.
  void markAbsent() {
    totalClasses++;
  }

  /// Resets attendance counts back to zero.
  void resetAttendance() {
    attendedClasses = 0;
    totalClasses = 0;
  }

  /// Calculates how many consecutive future classes must be attended to reach requiredAttendance (75%).
  int get classesNeededToReachTarget {
    if (totalClasses == 0) return 0;
    if (attendancePercentage >= requiredAttendance) return 0;

    // Formula: target = requiredAttendance / 100 (0.75)
    // needed = ((target * totalClasses) - attendedClasses) / (1 - target)
    const double target = requiredAttendance / 100.0;
    final double needed =
        ((target * totalClasses) - attendedClasses) / (1.0 - target);

    final int result = needed.ceil();
    return result < 0 ? 0 : result;
  }

  /// Calculates how many future classes can be missed while remaining at or above requiredAttendance (75%).
  int get classesCanMiss {
    if (totalClasses == 0) return 0;
    if (attendancePercentage < requiredAttendance) return 0;

    // Formula: target = requiredAttendance / 100 (0.75)
    // canMiss = (attendedClasses / target) - totalClasses
    const double target = requiredAttendance / 100.0;
    final double canMiss = (attendedClasses / target) - totalClasses;

    final int result = canMiss.floor();
    return result < 0 ? 0 : result;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'attendedClasses': attendedClasses,
      'totalClasses': totalClasses,
    };
  }

  factory AttendanceCourse.fromJson(Map<String, dynamic> json) {
    return AttendanceCourse(
      id: json['id'] as String,
      courseId: json['courseId'] as String?,
      courseName: json['courseName'] as String,
      attendedClasses: json['attendedClasses'] as int? ?? 0,
      totalClasses: json['totalClasses'] as int? ?? 0,
    );
  }
}
