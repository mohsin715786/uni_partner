class Course {
  final String id;
  final String courseName;
  final String courseCode;
  final int creditHours;
  final String instructor;

  Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.creditHours,
    this.instructor = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'creditHours': creditHours,
      'instructor': instructor,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String,
      creditHours: json['creditHours'] as int,
      instructor: json['instructor'] as String? ?? '',
    );
  }
}
