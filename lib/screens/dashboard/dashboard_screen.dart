import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/assignment_model.dart';
import 'package:uni_partner/models/attendance_model.dart';
import 'package:uni_partner/models/semester_model.dart';
import 'package:uni_partner/models/timetable_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/providers/auth_provider.dart';
import 'package:uni_partner/screens/profile/profile_screen.dart';
import 'package:uni_partner/utils/gpa_calculator.dart';
import 'package:uni_partner/widgets/dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // ==========================================
  // NEXT CLASS CALCULATION HELPERS
  // ==========================================
  int _weekdayToInt(String day) {
    switch (day.trim().toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final cleanStr = timeStr.trim().toUpperCase();
      if (cleanStr.isEmpty) return null;

      final parts = cleanStr.split(RegExp(r'\s+'));

      if (parts.length == 2) {
        // 12-hour format with AM/PM e.g. "09:00 AM" or "2:30 PM"
        final timeParts = parts[0].split(':');
        if (timeParts.length != 2) return null;

        final rawHour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        final period = parts[1];

        if (rawHour == null || minute == null) return null;
        if (rawHour < 1 || rawHour > 12) return null;
        if (minute < 0 || minute > 59) return null;
        if (period != 'AM' && period != 'PM') return null;

        int hour = rawHour;
        if (period == 'PM' && hour < 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      } else if (parts.length == 1) {
        // 24-hour format e.g. "14:30" or "09:00" or "00:10"
        final timeParts = parts[0].split(':');
        if (timeParts.length != 2) return null;

        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour == null || minute == null) return null;
        if (hour < 0 || hour > 23) return null;
        if (minute < 0 || minute > 59) return null;

        return TimeOfDay(hour: hour, minute: minute);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  DateTime? _getNextOccurrence(TimetableEntry entry, DateTime now) {
    final targetWeekday = _weekdayToInt(entry.day);
    final startTod = _parseTimeString(entry.startTime);
    if (startTod == null) return null;

    int daysAhead = targetWeekday - now.weekday;

    if (daysAhead < 0) {
      daysAhead += 7;
    } else if (daysAhead == 0) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        startTod.hour,
        startTod.minute,
      );
      if (candidate.isBefore(now)) {
        daysAhead = 7;
      }
    }

    final targetDate = now.add(Duration(days: daysAhead));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      startTod.hour,
      startTod.minute,
    );
  }

  _NextClassInfo? _getNextClassInfo(List<TimetableEntry> entries) {
    if (entries.isEmpty) return null;

    final now = DateTime.now();
    _NextClassInfo? nextInfo;

    for (final entry in entries) {
      final classTime = _getNextOccurrence(entry, now);
      if (classTime == null) continue;

      if (nextInfo == null || classTime.isBefore(nextInfo.classDateTime)) {
        nextInfo = _NextClassInfo(entry: entry, classDateTime: classTime);
      }
    }

    return nextInfo;
  }

  String _getTimeUntilClass(DateTime classDateTime) {
    final now = DateTime.now();
    final difference = classDateTime.difference(now);

    if (difference.inMinutes <= 0) {
      return 'Starting now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'Starts in $mins ${mins == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24 && classDateTime.day == now.day) {
      final hours = difference.inHours;
      return 'Starts in $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else if (classDateTime.day == now.day + 1 ||
        (difference.inHours >= 12 && difference.inHours < 36)) {
      return 'Tomorrow';
    } else {
      final days = (difference.inHours / 24).ceil();
      return 'In $days days';
    }
  }

  // ==========================================
  // DAILY SMART BRIEFING GENERATOR LOGIC
  // ==========================================
  List<_BriefingItem> _buildDailyBriefing(AppDataProvider appData) {
    final List<_BriefingItem> items = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. OVERDUE & TODAY/TOMORROW ASSIGNMENTS
    final pendingAssignments =
        appData.assignments.where((a) => !a.isCompleted).toList();

    int overdueCount = 0;
    int dueTodayCount = 0;
    Assignment? firstDueTomorrow;

    for (final assignment in pendingAssignments) {
      final due = DateTime(
        assignment.dueDate.year,
        assignment.dueDate.month,
        assignment.dueDate.day,
      );

      if (due.isBefore(today)) {
        overdueCount++;
      } else if (due.isAtSameMomentAs(today)) {
        dueTodayCount++;
      } else if (due.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
        firstDueTomorrow ??= assignment;
      }
    }

    if (overdueCount > 0) {
      items.add(
        _BriefingItem(
          icon: Icons.error_outline,
          message:
              '$overdueCount ${overdueCount == 1 ? "assignment is" : "assignments are"} overdue.',
          color: Colors.red,
          priority: 1,
        ),
      );
    }

    if (dueTodayCount > 0) {
      items.add(
        _BriefingItem(
          icon: Icons.assignment_late_outlined,
          message:
              '$dueTodayCount ${dueTodayCount == 1 ? "assignment is" : "assignments are"} due today.',
          color: Colors.orange.shade900,
          priority: 3,
        ),
      );
    }

    if (firstDueTomorrow != null) {
      items.add(
        _BriefingItem(
          icon: Icons.assignment_outlined,
          message: '"${firstDueTomorrow.title}" is due tomorrow.',
          color: Colors.amber.shade800,
          priority: 6,
        ),
      );
    }

    // 2. EXAMS (Today, Tomorrow, or Within 7 Days)
    final futureExams = appData.exams.where((e) => !e.isPast).toList();
    futureExams.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));

    if (futureExams.isNotEmpty) {
      final nextExam = futureExams.first;
      final examDay = DateTime(
        nextExam.examDateTime.year,
        nextExam.examDateTime.month,
        nextExam.examDateTime.day,
      );

      final diffDays = examDay.difference(today).inDays;

      if (diffDays == 0) {
        items.add(
          _BriefingItem(
            icon: Icons.event_note,
            message: '"${nextExam.courseName}" exam is today!',
            color: Colors.red,
            priority: 2,
          ),
        );
      } else if (diffDays == 1) {
        items.add(
          _BriefingItem(
            icon: Icons.event_note,
            message: '"${nextExam.courseName}" exam is tomorrow.',
            color: Colors.deepOrange,
            priority: 5,
          ),
        );
      } else if (diffDays > 1 && diffDays <= 7) {
        items.add(
          _BriefingItem(
            icon: Icons.event_note,
            message: '"${nextExam.courseName}" exam is in $diffDays days.',
            color: Colors.orange.shade800,
            priority: 5,
          ),
        );
      }
    }

    // 3. LOW ATTENDANCE WARNING
    final lowAttendanceCourses = appData.attendanceCourses
        .where((c) =>
            c.totalClasses > 0 &&
            c.attendancePercentage < AttendanceCourse.requiredAttendance)
        .toList();

    lowAttendanceCourses.sort(
      (a, b) => a.attendancePercentage.compareTo(b.attendancePercentage),
    );

    if (lowAttendanceCourses.isNotEmpty) {
      final lowest = lowAttendanceCourses.first;
      final pct = lowest.attendancePercentage.toStringAsFixed(0);
      final needed = lowest.classesNeededToReachTarget;

      String attendanceMsg = '${lowest.courseName} attendance is $pct%.';
      if (needed > 0) {
        attendanceMsg +=
            ' Attend the next $needed ${needed == 1 ? "class" : "classes"} to reach 75%.';
      }

      items.add(
        _BriefingItem(
          icon: Icons.warning_amber_rounded,
          message: attendanceMsg,
          color: Colors.amber.shade900,
          priority: 4,
        ),
      );
    }

    // 4. TODAY'S CLASSES & NEXT CLASS
    final todayClasses = appData.timetableEntries
        .where((entry) => _weekdayToInt(entry.day) == now.weekday)
        .toList();

    if (todayClasses.isNotEmpty) {
      items.add(
        _BriefingItem(
          icon: Icons.calendar_today_outlined,
          message:
              'You have ${todayClasses.length} ${todayClasses.length == 1 ? "class" : "classes"} scheduled today.',
          color: Colors.indigo,
          priority: 7,
        ),
      );
    }

    // Sort items by priority ascending
    items.sort((a, b) => a.priority.compareTo(b.priority));

    // Fallback if no urgent or scheduled items exist
    if (items.isEmpty) {
      items.add(
        const _BriefingItem(
          icon: Icons.check_circle_outline,
          message: "You're all caught up! No urgent academic tasks today.",
          color: Colors.green,
          priority: 8,
        ),
      );
    }

    // Limit briefing display to top 4 items
    return items.take(4).toList();
  }

  // ==========================================
  // ASSIGNMENT HELPERS
  // ==========================================
  String _getDueMessage(Assignment assignment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      assignment.dueDate.year,
      assignment.dueDate.month,
      assignment.dueDate.day,
    );

    final differenceInDays = dueDay.difference(today).inDays;

    if (differenceInDays == 0) {
      return 'Due Today';
    } else if (differenceInDays == 1) {
      return 'Due Tomorrow';
    } else if (differenceInDays > 1) {
      return 'Due in $differenceInDays Days';
    } else {
      return 'Overdue';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // ==========================================
  // EXAM FORMATTING HELPERS
  // ==========================================
  String _formatExamDate(DateTime dt) {
    final monthStr = _months[dt.month - 1];
    return '$monthStr ${dt.day}, ${dt.year}';
  }

  String _formatExamTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $period';
  }

  String _getExamCountdownSummary(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = examDay.difference(today).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays > 1) return '$diffDays Days';
    return 'Past';
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();

    final fullName = auth.currentUser?.fullName.trim();
    final firstName = (fullName != null && fullName.isNotEmpty)
        ? fullName.split(' ').first
        : 'Student';

    if (appData.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Generate Smart Daily Briefing
    final briefingItems = _buildDailyBriefing(appData);

    final pendingAssignments = appData.assignments
        .where(
          (assignment) =>
              !assignment.isCompleted && !assignment.isOverdue,
        )
        .toList();

    final sortedPending = [...pendingAssignments];
    sortedPending.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    int totalAttended = 0;
    int totalClasses = 0;
    for (final course in appData.attendanceCourses) {
      totalAttended += course.attendedClasses;
      totalClasses += course.totalClasses;
    }

    final double overallAttendance =
        totalClasses == 0 ? 0.0 : (totalAttended / totalClasses) * 100.0;

    final lowAttendanceCourses = appData.attendanceCourses
        .where((c) =>
            c.totalClasses > 0 &&
            c.attendancePercentage < AttendanceCourse.requiredAttendance)
        .toList();

    lowAttendanceCourses.sort(
      (a, b) => a.attendancePercentage.compareTo(b.attendancePercentage),
    );

    final lowestCourse =
        lowAttendanceCourses.isNotEmpty ? lowAttendanceCourses.first : null;

    final currentGpa =
        GpaCalculator.calculateGpa(appData.currentSemesterCourses);

    final allSemesters = [
      ...appData.previousSemesters,
      SemesterResult(
        id: 'current',
        semesterName: 'Current Semester',
        courses: appData.currentSemesterCourses,
      ),
    ];

    final cgpa = GpaCalculator.calculateCgpa(allSemesters);

    final nextClassInfo = _getNextClassInfo(appData.timetableEntries);
    final nextExam = appData.nextUpcomingExam;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Student Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Good Morning, $firstName 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what needs your attention today.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // DAILY SMART BRIEFING CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Today's Briefing",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Local Smart Sync',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...briefingItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: item.color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[850],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // NEXT CLASS CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEXT CLASS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled,
                              size: 16,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nextClassInfo == null
                                  ? 'No classes'
                                  : _getTimeUntilClass(
                                      nextClassInfo.classDateTime,
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nextClassInfo == null
                          ? 'No upcoming classes'
                          : nextClassInfo.entry.courseName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (nextClassInfo != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${nextClassInfo.entry.startTime} - ${nextClassInfo.entry.endTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Room: ${nextClassInfo.entry.room}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Your timetable is currently empty',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ACADEMIC SUMMARY CARDS (2-Column Grid)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                DashboardCard(
                  title: 'Attendance',
                  value: '${overallAttendance.toStringAsFixed(0)}%',
                  subtitle: appData.attendanceCourses.isEmpty
                      ? 'No data'
                      : '${appData.attendanceCourses.length} Courses',
                  icon: Icons.fact_check,
                  color: Colors.orange,
                ),
                DashboardCard(
                  title: 'Assignments',
                  value: '${pendingAssignments.length} Pending',
                  subtitle: sortedPending.isNotEmpty
                      ? 'Next: ${sortedPending.first.title}'
                      : 'No pending',
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
                DashboardCard(
                  title: 'Upcoming Exam',
                  value: nextExam == null
                      ? 'No Exam'
                      : _getExamCountdownSummary(nextExam.examDateTime),
                  subtitle: nextExam == null
                      ? 'None scheduled'
                      : nextExam.courseName,
                  icon: Icons.event_note,
                  color: Colors.red,
                ),
                DashboardCard(
                  title: 'Current GPA',
                  value: currentGpa.toStringAsFixed(2),
                  subtitle: 'CGPA: ${cgpa.toStringAsFixed(2)}',
                  icon: Icons.school,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ATTENDANCE WARNING CARD / ON-TRACK BANNER
            if (lowestCourse != null)
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade900,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Alert',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lowestCourse.courseName} attendance is ${lowestCourse.attendancePercentage.toStringAsFixed(0)}%. You need to attend the next ${lowestCourse.classesNeededToReachTarget} ${lowestCourse.classesNeededToReachTarget == 1 ? 'class' : 'classes'} to reach 75%.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance On Track',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your attendance is currently on track across all courses.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade800,
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

            // UPCOMING ASSIGNMENTS SECTION
            const Text(
              'Upcoming Assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (sortedPending.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No pending assignments.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ...sortedPending.take(2).map((assignment) {
                final priorityColor =
                    _getPriorityColor(assignment.priority);
                final dueMessage = _getDueMessage(assignment);

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child:
                          Icon(Icons.assignment_outlined, color: Colors.white),
                    ),
                    title: Text(
                      assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                        '${assignment.courseName} • $dueMessage'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        assignment.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            // REAL UPCOMING EXAM SECTION
            const Text(
              'Upcoming Exam',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (nextExam == null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No upcoming exams scheduled.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_note,
                          color: Colors.red.shade700,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextExam.courseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextExam.examTitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatExamDate(nextExam.examDateTime),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatExamTime(nextExam.examDateTime),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NextClassInfo {
  final TimetableEntry entry;
  final DateTime classDateTime;

  _NextClassInfo({required this.entry, required this.classDateTime});
}

class _BriefingItem {
  final IconData icon;
  final String message;
  final Color color;
  final int priority;

  const _BriefingItem({
    required this.icon,
    required this.message,
    required this.color,
    required this.priority,
  });
}
