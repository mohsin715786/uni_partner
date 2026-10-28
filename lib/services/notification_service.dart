import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uni_partner/models/assignment_model.dart';
import 'package:uni_partner/models/exam_model.dart';
import 'package:uni_partner/models/timetable_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'academic_reminders';
  static const String _channelName = 'Academic Reminders';
  static const String _channelDescription =
      'Notifications for exams, assignments, and classes';

  /// Initializes timezone data and Flutter Local Notifications plugin.
  Future<void> initialize() async {
    // 1. Initialize timezone database
    tz_data.initializeTimeZones();

    // 2. Retrieve device timezone and set tz.local
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      debugPrint('Device timezone initialized: $timeZoneName');
    } catch (e) {
      debugPrint('Error getting device timezone, falling back to UTC: $e');
    }

    // 3. Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    // 4. Request Android notification permission for Android 13+ (API 33+)
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // ==========================================
  // NOTIFICATION ID NAMESPACING HELPERS
  // ==========================================
  int _safeNotificationId(String value) {
    return value.hashCode.abs() % 100000000;
  }

  int getExamNotificationId(String examId) {
    return _safeNotificationId('exam_$examId');
  }

  int getAssignmentNotificationId(String assignmentId) {
    return _safeNotificationId('assignment_$assignmentId');
  }

  int getClassNotificationId(String classId) {
    return _safeNotificationId('class_$classId');
  }

  // ==========================================
  // IMMEDIATE TEST NOTIFICATION
  // ==========================================
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: 'UniPartner',
      body: 'Notifications are working.',
      notificationDetails: details,
    );
  }

  // ==========================================
  // EXAM REMINDERS
  // ==========================================
  Future<void> scheduleExamReminder({
    required int id,
    required String courseName,
    required String examTitle,
    required DateTime examDateTime,
  }) async {
    final now = DateTime.now();

    final preferredReminder = examDateTime.subtract(const Duration(days: 1));
    final fallbackReminder = examDateTime.subtract(const Duration(hours: 1));

    DateTime? targetReminderTime;
    String notificationTitle = 'Exam Tomorrow';

    if (preferredReminder.isAfter(now)) {
      targetReminderTime = preferredReminder;
      notificationTitle = 'Exam Tomorrow';
    } else if (fallbackReminder.isAfter(now)) {
      targetReminderTime = fallbackReminder;
      notificationTitle = 'Exam Starting Soon';
    } else {
      debugPrint(
          'Skipped Exam reminder for $courseName because reminder time already passed.');
      return;
    }

    final scheduledTzDateTime =
        tz.TZDateTime.from(targetReminderTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: notificationTitle,
        body: '$courseName - $examTitle',
        scheduledDate: scheduledTzDateTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
          'Scheduled exam reminder for $courseName ($examTitle) at $scheduledTzDateTime');
    } catch (e) {
      debugPrint('Error scheduling exam notification: $e');
    }
  }

  Future<void> syncExamReminders(List<Exam> exams) async {
    final futureExams = exams.where((e) => !e.isPast).toList();
    debugPrint('Synchronizing ${futureExams.length} future exam reminders.');

    for (final exam in futureExams) {
      final notifId = getExamNotificationId(exam.id);
      await scheduleExamReminder(
        id: notifId,
        courseName: exam.courseName,
        examTitle: exam.examTitle,
        examDateTime: exam.examDateTime,
      );
    }
  }

  // ==========================================
  // ASSIGNMENT REMINDERS
  // ==========================================
  Future<void> scheduleAssignmentReminder({
    required int id,
    required String assignmentTitle,
    required String courseName,
    required DateTime dueDate,
  }) async {
    final now = DateTime.now();

    final dueDay = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );

    // Normal reminder: 9:00 AM on the day BEFORE the due date
    final preferredReminder = DateTime(
      dueDay.year,
      dueDay.month,
      dueDay.day - 1,
      9,
      0,
    );

    // Fallback reminder: 9:00 AM on the assignment due date
    final fallbackReminder = DateTime(
      dueDay.year,
      dueDay.month,
      dueDay.day,
      9,
      0,
    );

    DateTime? targetReminderTime;
    String notificationTitle = 'Assignment Due Tomorrow';

    if (preferredReminder.isAfter(now)) {
      targetReminderTime = preferredReminder;
      notificationTitle = 'Assignment Due Tomorrow';
    } else if (fallbackReminder.isAfter(now)) {
      targetReminderTime = fallbackReminder;
      notificationTitle = 'Assignment Due Today';
    } else {
      debugPrint(
          'Skipped Assignment reminder for $assignmentTitle because reminder time already passed.');
      return;
    }

    final scheduledTzDateTime =
        tz.TZDateTime.from(targetReminderTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: notificationTitle,
        body: '$courseName - $assignmentTitle',
        scheduledDate: scheduledTzDateTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
          'Scheduled assignment reminder for $courseName ($assignmentTitle) at $scheduledTzDateTime');
    } catch (e) {
      debugPrint('Error scheduling assignment notification: $e');
    }
  }

  Future<void> syncAssignmentReminders(List<Assignment> assignments) async {
    final validAssignments =
        assignments.where((a) => !a.isCompleted && !a.isOverdue).toList();

    debugPrint(
        'Synchronizing ${validAssignments.length} pending assignment reminders.');

    for (final assignment in validAssignments) {
      final notifId = getAssignmentNotificationId(assignment.id);
      await scheduleAssignmentReminder(
        id: notifId,
        assignmentTitle: assignment.title,
        courseName: assignment.courseName,
        dueDate: assignment.dueDate,
      );
    }
  }

  // ==========================================
  // TIMETABLE / CLASS REMINDERS
  // ==========================================
  int? _weekdayFromName(String day) {
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
        return null;
    }
  }

  _TimeParts? _parseStartTime(String timeStr) {
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

        return _TimeParts(hour: hour, minute: minute);
      } else if (parts.length == 1) {
        // 24-hour format e.g. "14:30" or "09:00" or "00:10"
        final timeParts = parts[0].split(':');
        if (timeParts.length != 2) return null;

        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour == null || minute == null) return null;
        if (hour < 0 || hour > 23) return null;
        if (minute < 0 || minute > 59) return null;

        return _TimeParts(hour: hour, minute: minute);
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing start time "$timeStr": $e');
      return null;
    }
  }

  Future<void> scheduleClassReminder({
    required int id,
    required String courseName,
    required String day,
    required String startTime,
    required String room,
  }) async {
    final targetWeekday = _weekdayFromName(day);
    if (targetWeekday == null) {
      debugPrint('Skipped class reminder for $courseName: invalid day "$day"');
      return;
    }

    final timeParts = _parseStartTime(startTime);
    if (timeParts == null) {
      debugPrint('Skipped class reminder for $courseName: invalid time "$startTime"');
      return;
    }

    final now = DateTime.now();
    int daysAhead = (targetWeekday - now.weekday + 7) % 7;

    DateTime classCandidate = DateTime(
      now.year,
      now.month,
      now.day + daysAhead,
      timeParts.hour,
      timeParts.minute,
    );

    DateTime reminderCandidate =
        classCandidate.subtract(const Duration(minutes: 15));

    if (!reminderCandidate.isAfter(now)) {
      classCandidate = classCandidate.add(const Duration(days: 7));
      reminderCandidate = classCandidate.subtract(const Duration(minutes: 15));
    }

    final scheduledTzDateTime =
        tz.TZDateTime.from(reminderCandidate, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Class Starting Soon',
        body: '$courseName starts in 15 minutes - Room $room',
        scheduledDate: scheduledTzDateTime,
        notificationDetails:
            const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint(
          'Scheduled weekly class reminder for $courseName at $scheduledTzDateTime');
    } catch (e) {
      debugPrint('Error scheduling class notification: $e');
    }
  }

  Future<void> syncClassReminders(List<TimetableEntry> entries) async {
    debugPrint('Synchronizing ${entries.length} class reminders.');

    for (final entry in entries) {
      try {
        final notifId = getClassNotificationId(entry.id);
        await scheduleClassReminder(
          id: notifId,
          courseName: entry.courseName,
          day: entry.day,
          startTime: entry.startTime,
          room: entry.room,
        );
      } catch (e) {
        debugPrint('Error syncing class reminder for ${entry.courseName}: $e');
      }
    }
  }

  // ==========================================
  // DEBUG TEST HELPERS
  // ==========================================
  Future<void> scheduleTestReminderInOneMinute({
    required int id,
    required String courseName,
    required String examTitle,
  }) async {
    final reminderTime = DateTime.now().add(const Duration(minutes: 1));
    final scheduledTzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Exam Test Reminder',
        body: '$courseName - $examTitle (1 Minute Test)',
        scheduledDate: scheduledTzDateTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Scheduled 1-minute test reminder at $scheduledTzDateTime');
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
    }
  }

  Future<void> scheduleTestAssignmentReminderInOneMinute({
    required int id,
    required String courseName,
    required String assignmentTitle,
  }) async {
    final reminderTime = DateTime.now().add(const Duration(minutes: 1));
    final scheduledTzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Assignment Test Reminder',
        body: '$courseName - $assignmentTitle (1 Minute Test)',
        scheduledDate: scheduledTzDateTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
          'Scheduled 1-minute assignment test reminder at $scheduledTzDateTime');
    } catch (e) {
      debugPrint('Error scheduling assignment test notification: $e');
    }
  }

  Future<void> scheduleTestClassReminderInOneMinute({
    required int id,
    required String courseName,
    required String room,
  }) async {
    final reminderTime = DateTime.now().add(const Duration(minutes: 1));
    final scheduledTzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Class Test Reminder',
        body: '$courseName starts in 15 minutes - Room $room (1 Minute Test)',
        scheduledDate: scheduledTzDateTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
          'Scheduled 1-minute class test reminder at $scheduledTzDateTime');
    } catch (e) {
      debugPrint('Error scheduling class test notification: $e');
    }
  }

  /// Cancels a scheduled notification by integer ID.
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}

class _TimeParts {
  final int hour;
  final int minute;
  _TimeParts({required this.hour, required this.minute});
}
