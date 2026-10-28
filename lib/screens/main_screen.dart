import 'package:flutter/material.dart';
import 'package:uni_partner/screens/assignments/assignment_screen.dart';
import 'package:uni_partner/screens/attendance/attendance_screen.dart';
import 'package:uni_partner/screens/dashboard/dashboard_screen.dart';
import 'package:uni_partner/screens/exams/exam_screen.dart';
import 'package:uni_partner/screens/gpa/gpa_screen.dart';
import 'package:uni_partner/screens/timetable/timetable_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    TimetableScreen(),
    AttendanceScreen(),
    AssignmentScreen(),
    ExamScreen(),
    GpaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'GPA',
          ),
        ],
      ),
    );
  }
}
