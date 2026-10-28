import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_partner/models/assignment_model.dart';
import 'package:uni_partner/models/attendance_model.dart';
import 'package:uni_partner/models/course_model.dart';
import 'package:uni_partner/models/exam_model.dart';
import 'package:uni_partner/models/semester_model.dart';
import 'package:uni_partner/models/semester_settings_model.dart';
import 'package:uni_partner/models/timetable_model.dart';
import 'package:uni_partner/services/notification_service.dart';

class AppDataProvider extends ChangeNotifier {
  // Storage Keys
  static const String _timetableKey = 'timetable_entries';
  static const String _attendanceKey = 'attendance_courses';
  static const String _assignmentsKey = 'assignments';
  static const String _currentCoursesKey = 'current_semester_courses';
  static const String _previousSemestersKey = 'previous_semesters';
  static const String _examsKey = 'exams';
  static const String _coursesKey = 'courses';
  static const String _semesterSettingsKey = 'semester_settings';

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // In-Memory Data Lists
  List<TimetableEntry> _timetableEntries = [];
  List<AttendanceCourse> _attendanceCourses = [];
  List<Assignment> _assignments = [];
  List<CourseGrade> _currentSemesterCourses = [];
  List<SemesterResult> _previousSemesters = [];
  List<Exam> _exams = [];
  List<Course> _courses = [];
  SemesterSettings? _semesterSettings;

  AppDataProvider() {
    loadData();
  }

  // ==========================================
  // PERSISTENCE LOADING
  // ==========================================
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Semester Settings
      final settingsString = prefs.getString(_semesterSettingsKey);
      if (settingsString != null && settingsString.isNotEmpty) {
        _semesterSettings = SemesterSettings.fromJson(
          jsonDecode(settingsString) as Map<String, dynamic>,
        );
      } else {
        _semesterSettings = null;
      }

      // Load Courses
      final coursesString = prefs.getString(_coursesKey);
      if (coursesString != null && coursesString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(coursesString);
        _courses = jsonList
            .map((item) => Course.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _courses = [];
      }

      // Load Timetable
      final timetableString = prefs.getString(_timetableKey);
      if (timetableString != null && timetableString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(timetableString);
        _timetableEntries = jsonList
            .map((item) =>
                TimetableEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _timetableEntries = [];
      }

      // Load Attendance
      final attendanceString = prefs.getString(_attendanceKey);
      if (attendanceString != null && attendanceString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(attendanceString);
        _attendanceCourses = jsonList
            .map((item) =>
                AttendanceCourse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _attendanceCourses = [];
      }

      // Load Assignments
      final assignmentsString = prefs.getString(_assignmentsKey);
      if (assignmentsString != null && assignmentsString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(assignmentsString);
        _assignments = jsonList
            .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _assignments = [];
      }

      // Load Current Semester Courses
      final currentCoursesString = prefs.getString(_currentCoursesKey);
      if (currentCoursesString != null && currentCoursesString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(currentCoursesString);
        _currentSemesterCourses = jsonList
            .map((item) => CourseGrade.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _currentSemesterCourses = [];
      }

      // Load Previous Semesters
      final previousSemestersString = prefs.getString(_previousSemestersKey);
      if (previousSemestersString != null &&
          previousSemestersString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(previousSemestersString);
        _previousSemesters = jsonList
            .map((item) =>
                SemesterResult.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _previousSemesters = [];
      }

      // Load Exams
      final examsString = prefs.getString(_examsKey);
      if (examsString != null && examsString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(examsString);
        _exams = jsonList
            .map((item) => Exam.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _exams = [];
      }

      // Synchronize notifications for future loaded exams, pending assignments, and class schedules
      await NotificationService.instance.syncExamReminders(_exams);
      await NotificationService.instance.syncAssignmentReminders(_assignments);
      await NotificationService.instance.syncClassReminders(_timetableEntries);
    } catch (e) {
      debugPrint('Error loading data from SharedPreferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // PERSISTENCE SAVING HELPERS
  // ==========================================
  Future<void> _saveSemesterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_semesterSettings != null) {
        final jsonString = jsonEncode(_semesterSettings!.toJson());
        await prefs.setString(_semesterSettingsKey, jsonString);
      }
    } catch (e) {
      debugPrint('Error saving semester settings: $e');
    }
  }

  Future<void> _saveCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_courses.map((e) => e.toJson()).toList());
      await prefs.setString(_coursesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving courses: $e');
    }
  }

  Future<void> _saveTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(_timetableEntries.map((e) => e.toJson()).toList());
      await prefs.setString(_timetableKey, jsonString);
    } catch (e) {
      debugPrint('Error saving timetable: $e');
    }
  }

  Future<void> _saveAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(_attendanceCourses.map((e) => e.toJson()).toList());
      await prefs.setString(_attendanceKey, jsonString);
    } catch (e) {
      debugPrint('Error saving attendance: $e');
    }
  }

  Future<void> _saveAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(_assignments.map((e) => e.toJson()).toList());
      await prefs.setString(_assignmentsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving assignments: $e');
    }
  }

  Future<void> _saveCurrentSemesterCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
          _currentSemesterCourses.map((e) => e.toJson()).toList());
      await prefs.setString(_currentCoursesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving current semester courses: $e');
    }
  }

  Future<void> savePreviousSemesters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(_previousSemesters.map((e) => e.toJson()).toList());
      await prefs.setString(_previousSemestersKey, jsonString);
    } catch (e) {
      debugPrint('Error saving previous semesters: $e');
    }
  }

  Future<void> _saveExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(_exams.map((e) => e.toJson()).toList());
      await prefs.setString(_examsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving exams: $e');
    }
  }

  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_timetableKey);
      await prefs.remove(_attendanceKey);
      await prefs.remove(_assignmentsKey);
      await prefs.remove(_currentCoursesKey);
      await prefs.remove(_previousSemestersKey);
      await prefs.remove(_examsKey);
      await prefs.remove(_coursesKey);
      await prefs.remove(_semesterSettingsKey);

      _timetableEntries = [];
      _attendanceCourses = [];
      _assignments = [];
      _currentSemesterCourses = [];
      _previousSemesters = [];
      _exams = [];
      _courses = [];
      _semesterSettings = null;

      await savePreviousSemesters();

      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting data: $e');
    }
  }

  // ==========================================
  // SEMESTER SETTINGS
  // ==========================================
  SemesterSettings? get semesterSettings => _semesterSettings;

  void setSemesterSettings(SemesterSettings settings) {
    _semesterSettings = settings;
    notifyListeners();
    _saveSemesterSettings();
  }

  // ==========================================
  // COURSES
  // ==========================================
  List<Course> get courses => _courses;

  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  void addCourse(Course course) {
    _courses.add(course);
    notifyListeners();
    _saveCourses();
  }

  void updateCourse(Course updatedCourse) {
    final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) {
      _courses[index] = updatedCourse;
      notifyListeners();
      _saveCourses();
    }
  }

  void deleteCourse(String id) {
    _courses.removeWhere((c) => c.id == id);
    notifyListeners();
    _saveCourses();
  }

  // ==========================================
  // TIMETABLE
  // ==========================================
  List<TimetableEntry> get timetableEntries => _timetableEntries;

  /// Returns the number of weekly class slots for a given course ID.
  int getWeeklyClassCountForCourse(String courseId) {
    final targetCourse = getCourseById(courseId);
    return _timetableEntries.where((entry) {
      if (entry.courseId != null && entry.courseId == courseId) {
        return true;
      }
      if (entry.courseId == null && targetCourse != null) {
        return entry.courseName.trim().toLowerCase() ==
            targetCourse.courseName.trim().toLowerCase();
      }
      return false;
    }).length;
  }

  void addTimetableEntry(TimetableEntry entry) {
    _timetableEntries.add(entry);
    notifyListeners();
    _saveTimetable();
  }

  void deleteTimetableEntry(String id) {
    _timetableEntries.removeWhere((entry) => entry.id == id);
    notifyListeners();
    _saveTimetable();
  }

  // ==========================================
  // ATTENDANCE
  // ==========================================
  List<AttendanceCourse> get attendanceCourses => _attendanceCourses;

  void addAttendanceCourse(AttendanceCourse course) {
    _attendanceCourses.add(course);
    notifyListeners();
    _saveAttendance();
  }

  void markPresent(String courseId) {
    final index = _attendanceCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _attendanceCourses[index].markPresent();
      notifyListeners();
      _saveAttendance();
    }
  }

  void markAbsent(String courseId) {
    final index = _attendanceCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _attendanceCourses[index].markAbsent();
      notifyListeners();
      _saveAttendance();
    }
  }

  void resetAttendance(String courseId) {
    final index = _attendanceCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _attendanceCourses[index].resetAttendance();
      notifyListeners();
      _saveAttendance();
    }
  }

  void deleteAttendanceCourse(String courseId) {
    _attendanceCourses.removeWhere((c) => c.id == courseId);
    notifyListeners();
    _saveAttendance();
  }

  // ==========================================
  // ASSIGNMENTS
  // ==========================================
  List<Assignment> get assignments => _assignments;

  void addAssignment(Assignment assignment) {
    _assignments.add(assignment);
    notifyListeners();
    _saveAssignments();
  }

  void toggleAssignmentCompleted(String id, bool value) {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _assignments[index].isCompleted = value;
      notifyListeners();
      _saveAssignments();
    }
  }

  void deleteAssignment(String id) {
    _assignments.removeWhere((a) => a.id == id);
    notifyListeners();
    _saveAssignments();
  }

  // ==========================================
  // GPA / CGPA
  // ==========================================
  List<CourseGrade> get currentSemesterCourses => _currentSemesterCourses;

  void addCurrentSemesterCourse(CourseGrade course) {
    _currentSemesterCourses.add(course);
    notifyListeners();
    _saveCurrentSemesterCourses();
  }

  void deleteCurrentSemesterCourse(String id) {
    _currentSemesterCourses.removeWhere((c) => c.id == id);
    notifyListeners();
    _saveCurrentSemesterCourses();
  }

  List<SemesterResult> get previousSemesters => _previousSemesters;

  // ==========================================
  // EXAMS
  // ==========================================
  List<Exam> get exams => _exams;

  Exam? get nextUpcomingExam {
    final futureExams = _exams.where((e) => !e.isPast).toList();
    if (futureExams.isEmpty) return null;
    futureExams.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));
    return futureExams.first;
  }

  void addExam(Exam exam) {
    _exams.add(exam);
    notifyListeners();
    _saveExams();
  }

  void deleteExam(String id) {
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
    _saveExams();
  }
}
