import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/attendance_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/screens/attendance/add_attendance_course_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  void _showDeleteDialog(AttendanceCourse course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Course?'),
          content: Text(
            'Are you sure you want to delete ${course.courseName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<AppDataProvider>()
                    .deleteAttendanceCourse(course.id);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartMessage(AttendanceCourse course) {
    if (course.totalClasses == 0) {
      return const Text(
        'No attendance recorded yet.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      );
    }

    if (course.attendancePercentage < AttendanceCourse.requiredAttendance) {
      final needed = course.classesNeededToReachTarget;
      final classText = needed == 1 ? 'class' : 'classes';
      return Text(
        'You need to attend the next $needed $classText to reach 75%.',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      final canMiss = course.classesCanMiss;
      final classText = canMiss == 1 ? 'class' : 'classes';
      return Text(
        'You can miss $canMiss $classText while staying at or above 75%.',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();
    final courses = appData.attendanceCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 1,
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.indigo,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Required Attendance: 75%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: courses.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No courses added yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap + to add a course.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final percentage = course.attendancePercentage;
                      final isLow =
                          percentage < AttendanceCourse.requiredAttendance;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      course.courseName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'reset') {
                                        context
                                            .read<AppDataProvider>()
                                            .resetAttendance(course.id);
                                      } else if (value == 'delete') {
                                        _showDeleteDialog(course);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'reset',
                                        child: Text('Reset Attendance'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Course',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${course.attendedClasses} / ${course.totalClasses} Classes',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Attendance: ${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isLow ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: course.totalClasses == 0
                                      ? 0.0
                                      : percentage / 100.0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  color: isLow ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSmartMessage(course),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<AppDataProvider>()
                                            .markPresent(course.id);
                                      },
                                      icon: const Icon(Icons.check),
                                      label: const Text('Present'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<AppDataProvider>()
                                            .markAbsent(course.id);
                                      },
                                      icon: const Icon(Icons.close),
                                      label: const Text('Absent'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'attendance_fab',
        onPressed: () async {
          final provider = context.read<AppDataProvider>();
          final newCourse = await Navigator.push<AttendanceCourse>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAttendanceCourseScreen(),
            ),
          );

          if (newCourse != null) {
            provider.addAttendanceCourse(newCourse);
          }
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
