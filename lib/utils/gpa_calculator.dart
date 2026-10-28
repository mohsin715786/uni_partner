import 'package:uni_partner/models/semester_model.dart';

class GpaCalculator {
  /// Converts letter grade to grade points.
  static double gradeToPoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return 4.00;
      case 'A-':
        return 3.67;
      case 'B+':
        return 3.33;
      case 'B':
        return 3.00;
      case 'B-':
        return 2.67;
      case 'C+':
        return 2.33;
      case 'C':
        return 2.00;
      case 'C-':
        return 1.67;
      case 'D+':
        return 1.33;
      case 'D':
        return 1.00;
      case 'F':
        return 0.00;
      default:
        return 0.00;
    }
  }

  /// Calculates GPA for a list of courses.
  /// Formula: Sum(gradePoint * creditHours) / Sum(creditHours)
  static double calculateGpa(List<CourseGrade> courses) {
    if (courses.isEmpty) return 0.0;

    double totalQualityPoints = 0.0;
    int totalCreditHours = 0;

    for (final course in courses) {
      final gradePoint = gradeToPoint(course.grade);
      totalQualityPoints += gradePoint * course.creditHours;
      totalCreditHours += course.creditHours;
    }

    if (totalCreditHours == 0) return 0.0;

    return totalQualityPoints / totalCreditHours;
  }

  /// Calculates cumulative CGPA across all semesters.
  /// Weighted calculation across ALL courses in all semesters.
  static double calculateCgpa(List<SemesterResult> semesters) {
    if (semesters.isEmpty) return 0.0;

    double totalQualityPoints = 0.0;
    int totalCreditHours = 0;

    for (final semester in semesters) {
      for (final course in semester.courses) {
        final gradePoint = gradeToPoint(course.grade);
        totalQualityPoints += gradePoint * course.creditHours;
        totalCreditHours += course.creditHours;
      }
    }

    if (totalCreditHours == 0) return 0.0;

    return totalQualityPoints / totalCreditHours;
  }

  /// Helper to calculate total credit hours for a course list.
  static int getTotalCreditHours(List<CourseGrade> courses) {
    return courses.fold(0, (sum, course) => sum + course.creditHours);
  }

  /// Helper to calculate total credit hours across all semesters.
  static int getTotalCreditHoursFromSemesters(List<SemesterResult> semesters) {
    int total = 0;
    for (final semester in semesters) {
      total += getTotalCreditHours(semester.courses);
    }
    return total;
  }
}
