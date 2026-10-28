import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/attendance_model.dart';
import 'package:uni_partner/models/course_model.dart';
import 'package:uni_partner/models/timetable_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/providers/auth_provider.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> {
  int _currentStep = 0;

  // Step 1: Student Info Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _universityController;
  late TextEditingController _departmentController;
  late TextEditingController _semesterController;

  // Step 2: Semester Dates
  late TextEditingController _semesterNameController;
  DateTime? _startDate;
  DateTime? _endDate;

  // Step 3: Courses List added during setup
  final List<Course> _addedCourses = [];

  // Temporary Course controllers for adding in Step 3
  final TextEditingController _courseNameCtrl = TextEditingController();
  final TextEditingController _courseCodeCtrl = TextEditingController();
  final TextEditingController _creditHoursCtrl = TextEditingController(text: '3');
  final TextEditingController _instructorCtrl = TextEditingController();

  // Step 4: Timetable entries added during setup
  final List<TimetableEntry> _addedTimetableEntries = [];

  // Temporary Timetable entry fields
  Course? _selectedTimetableCourse;
  String _selectedDay = 'Monday';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _roomCtrl = TextEditingController(text: 'Room 101');

  // Step 5: Initial Attendance Tracking
  final Map<String, int> _heldMap = {};
  final Map<String, int> _attendedMap = {};
  bool _startFromZero = false;
  bool _skipAttendance = false;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
    _semesterController = TextEditingController(text: user?.semester ?? 'Semester 1');

    _semesterNameController =
        TextEditingController(text: user?.semester ?? 'Semester 1');
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 120));

    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 30);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _semesterNameController.dispose();

    _courseNameCtrl.dispose();
    _courseCodeCtrl.dispose();
    _creditHoursCtrl.dispose();
    _instructorCtrl.dispose();

    _roomCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final hStr = hour.toString().padLeft(2, '0');
    final mStr = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hStr:$mStr $period';
  }

  void _addCourseToDraft() {
    final name = _courseNameCtrl.text.trim();
    final code = _courseCodeCtrl.text.trim();
    final credits = int.tryParse(_creditHoursCtrl.text.trim()) ?? 3;
    final instructor = _instructorCtrl.text.trim();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter course name and code.')),
      );
      return;
    }

    final newCourse = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseName: name,
      courseCode: code,
      creditHours: credits,
      instructor: instructor,
    );

    setState(() {
      _addedCourses.add(newCourse);
      _courseNameCtrl.clear();
      _courseCodeCtrl.clear();
      _creditHoursCtrl.text = '3';
      _instructorCtrl.clear();

      // Pre-select for timetable
      _selectedTimetableCourse ??= newCourse;
    });
  }

  void _addTimetableToDraft() {
    if (_selectedTimetableCourse == null) return;
    final room = _roomCtrl.text.trim();
    if (room.isEmpty) return;

    final entry = TimetableEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: _selectedTimetableCourse!.id,
      courseName: _selectedTimetableCourse!.courseName,
      day: _selectedDay,
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      room: room,
    );

    setState(() {
      _addedTimetableEntries.add(entry);
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Save profile info
      context.read<AuthProvider>().updateUserProfile(
            fullName: _fullNameController.text,
            university: _universityController.text,
            department: _departmentController.text,
            semester: _semesterController.text,
          );
    } else if (_currentStep == 2) {
      // Must add at least 1 course
      if (_addedCourses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one course.')),
        );
        return;
      }
    }

    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _finishSetup() async {
    final appData = context.read<AppDataProvider>();

    // 1. Populate Central Courses
    for (final course in _addedCourses) {
      appData.addCourse(course);
    }

    // 2. Populate Timetable
    for (final entry in _addedTimetableEntries) {
      appData.addTimetableEntry(entry);
    }

    // 3. Populate Attendance Courses
    if (!_skipAttendance) {
      for (final course in _addedCourses) {
        final held = _startFromZero ? 0 : (_heldMap[course.id] ?? 0);
        final attended = _startFromZero ? 0 : (_attendedMap[course.id] ?? 0);

        final attCourse = AttendanceCourse(
          id: DateTime.now().millisecondsSinceEpoch.toString() + course.id,
          courseId: course.id,
          courseName: course.courseName,
          attendedClasses: attended,
          totalClasses: held,
        );
        appData.addAttendanceCourse(attCourse);
      }
    }

    // Mark setup completed
    await context.read<AuthProvider>().completeInitialSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniPartner Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: NeoTheme.surface,
            child: Row(
              children: [
                Text(
                  'Step ${_currentStep + 1} of 6',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 6,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      color: NeoTheme.yellow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 2, thickness: 2, color: NeoTheme.stroke),

          // Main Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: NeoTheme.surface,
              border: Border(top: BorderSide(color: NeoTheme.stroke, width: 2)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0 && _currentStep < 5)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: NeoTheme.stroke, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: NeoTheme.stroke,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0 && _currentStep < 5)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == 5 ? _finishSetup : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 5 ? NeoTheme.mint : NeoTheme.yellow,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _currentStep == 5 ? 'Start Using UniPartner' : 'Continue',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1StudentInfo();
      case 1:
        return _buildStep2Semester();
      case 2:
        return _buildStep3Courses();
      case 3:
        return _buildStep4Timetable();
      case 4:
        return _buildStep5Attendance();
      case 5:
        return _buildStep6Completion();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Student Information
  Widget _buildStep1StudentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about you 👋',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm your student details to customize your dashboard.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 20),
        NeoCard(
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'University Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(labelText: 'Current Semester'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: Semester Setup
  Widget _buildStep2Semester() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set up your semester 🗓️',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure your academic term timeline.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 20),
        NeoCard(
          child: Column(
            children: [
              TextFormField(
                controller: _semesterNameController,
                decoration: const InputDecoration(labelText: 'Semester Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: Text(_startDate == null
                          ? 'Start Date'
                          : 'Start: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now().add(const Duration(days: 120)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: Text(_endDate == null
                          ? 'End Date'
                          : 'End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: Add Courses
  Widget _buildStep3Courses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add your courses 📚',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the subjects you are taking this semester.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 20),
        NeoCard(
          backgroundColor: NeoTheme.cyan.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseNameCtrl,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _courseCodeCtrl,
                      decoration: const InputDecoration(labelText: 'Course Code'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _creditHoursCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Credit Hours'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _instructorCtrl,
                decoration: const InputDecoration(labelText: 'Instructor (Optional)'),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _addCourseToDraft,
                icon: const Icon(Icons.add),
                label: const Text('+ Add Course To List'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Added Subjects:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (_addedCourses.isEmpty)
          const Text('No courses added yet. Please add at least one subject.')
        else
          ..._addedCourses.map(
            (c) => NeoCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(c.courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c.courseCode} • ${c.creditHours} Credits'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _addedCourses.removeWhere((item) => item.id == c.id);
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // STEP 4: Timetable
  Widget _buildStep4Timetable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Build your weekly timetable ⏰',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Add every regular weekly class. UniPartner uses your timetable to understand how often each course meets and to plan attendance.',
          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
        ),
        const SizedBox(height: 20),
        NeoCard(
          backgroundColor: NeoTheme.purple.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Course>(
                initialValue: _selectedTimetableCourse,
                decoration: const InputDecoration(labelText: 'Select Course'),
                items: _addedCourses
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.courseName)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTimetableCourse = val),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: _days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDay = val ?? 'Monday'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _roomCtrl,
                decoration: const InputDecoration(labelText: 'Room Number'),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _addTimetableToDraft,
                icon: const Icon(Icons.add),
                label: const Text('+ Add Class Slot'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scheduled Classes:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (_addedTimetableEntries.isEmpty)
          const Text('No timetable entries added yet.')
        else
          ..._addedTimetableEntries.map(
            (TimetableEntry e) => NeoCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                title: Text('${e.courseName} (${e.day})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${e.startTime} - ${e.endTime} • Room ${e.room}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _addedTimetableEntries.removeWhere((item) => item.id == e.id);
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // STEP 5: Initial Attendance
  Widget _buildStep5Attendance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where is your attendance right now? 📊',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Set your current attendance counts if installing mid-semester.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _startFromZero,
          title: const Text('Semester just started — start attendance from zero', style: TextStyle(fontWeight: FontWeight.bold)),
          onChanged: (val) {
            setState(() {
              _startFromZero = val ?? false;
              if (_startFromZero) _skipAttendance = false;
            });
          },
        ),
        CheckboxListTile(
          value: _skipAttendance,
          title: const Text('Set this up later', style: TextStyle(fontWeight: FontWeight.bold)),
          onChanged: (val) {
            setState(() {
              _skipAttendance = val ?? false;
              if (_skipAttendance) _startFromZero = false;
            });
          },
        ),
        const SizedBox(height: 16),
        if (!_startFromZero && !_skipAttendance)
          ..._addedCourses.map(
            (c) => NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.courseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Held So Far'),
                          onChanged: (v) => _heldMap[c.id] = int.tryParse(v) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Attended'),
                          onChanged: (v) => _attendedMap[c.id] = int.tryParse(v) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // STEP 6: Completion
  Widget _buildStep6Completion() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.stars, size: 80, color: NeoTheme.yellow),
        const SizedBox(height: 16),
        const Text(
          "You're Ready! 🎉",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personalized UniPartner workspace is configured.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),
        NeoCard(
          backgroundColor: NeoTheme.mint.withValues(alpha: 0.3),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('${_addedCourses.length} Courses Configured'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('${_addedTimetableEntries.length} Weekly Classes Scheduled'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Attendance Tracking Ready'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
