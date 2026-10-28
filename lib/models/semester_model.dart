class CourseGrade {
  final String id;
  final String courseName;
  final int creditHours;
  final String grade;

  CourseGrade({
    required this.id,
    required this.courseName,
    required this.creditHours,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'creditHours': creditHours,
      'grade': grade,
    };
  }

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    return CourseGrade(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      creditHours: json['creditHours'] as int? ?? 3,
      grade: json['grade'] as String,
    );
  }
}

class SemesterResult {
  final String id;
  final String semesterName;
  final List<CourseGrade> courses;

  SemesterResult({
    required this.id,
    required this.semesterName,
    required this.courses,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterName': semesterName,
      'courses': courses.map((course) => course.toJson()).toList(),
    };
  }

  factory SemesterResult.fromJson(Map<String, dynamic> json) {
    final coursesList = (json['courses'] as List<dynamic>?)
            ?.map((item) => CourseGrade.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return SemesterResult(
      id: json['id'] as String,
      semesterName: json['semesterName'] as String,
      courses: coursesList,
    );
  }
}
