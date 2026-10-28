import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/attendance_model.dart';
import 'package:uni_partner/models/course_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';

class AddAttendanceCourseScreen extends StatefulWidget {
  const AddAttendanceCourseScreen({super.key});

  @override
  State<AddAttendanceCourseScreen> createState() =>
      _AddAttendanceCourseScreenState();
}

class _AddAttendanceCourseScreenState
    extends State<AddAttendanceCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  Course? _selectedCourse;

  void _submitForm() {
    if (!_formKey.currentState!.validate() || _selectedCourse == null) return;

    final appData = context.read<AppDataProvider>();

    // Duplicate Check: prevent adding attendance for the same central course twice
    final isDuplicate = appData.attendanceCourses.any((a) {
      if (a.courseId != null && a.courseId == _selectedCourse!.id) {
        return true;
      }
      return a.courseName.trim().toLowerCase() ==
          _selectedCourse!.courseName.trim().toLowerCase();
    });

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance for this course already exists.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final newCourse = AttendanceCourse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: _selectedCourse!.id,
      courseName: _selectedCourse!.courseName,
    );

    Navigator.pop(context, newCourse);
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();
    final coursesList = appData.courses;

    if (_selectedCourse == null && coursesList.isNotEmpty) {
      _selectedCourse = coursesList.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Attendance Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (coursesList.isEmpty) ...[
                Card(
                  elevation: 0,
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No courses available.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add your subjects in Profile → My Courses first.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Course Dropdown
                DropdownButtonFormField<Course>(
                  initialValue: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  items: coursesList.map((Course course) {
                    return DropdownMenuItem<Course>(
                      value: course,
                      child: Text(
                        '${course.courseName} (${course.courseCode})',
                      ),
                    );
                  }).toList(),
                  onChanged: (Course? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCourse = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a course';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: (coursesList.isEmpty || _selectedCourse == null)
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Add Course',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
