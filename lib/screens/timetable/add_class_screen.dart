import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/course_model.dart';
import 'package:uni_partner/models/timetable_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _roomController = TextEditingController();

  Course? _selectedCourse;
  String _selectedDay = 'Monday';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _timeError = false;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  String _formatTimeForStorage(TimeOfDay time) {
    final hourOfPeriod = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final hourStr = hourOfPeriod.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final periodStr = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hourStr:$minuteStr $periodStr';
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _timeError = false;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 30),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _timeError = false;
      });
    }
  }

  void _submitForm() {
    final isValid = _formKey.currentState!.validate();

    if (_startTime == null || _endTime == null) {
      setState(() {
        _timeError = true;
      });
      return;
    }

    if (!isValid || _selectedCourse == null) return;

    final newEntry = TimetableEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: _selectedCourse!.id,
      courseName: _selectedCourse!.courseName,
      day: _selectedDay,
      startTime: _formatTimeForStorage(_startTime!),
      endTime: _formatTimeForStorage(_endTime!),
      room: _roomController.text.trim(),
    );

    Navigator.pop(context, newEntry);
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();
    final coursesList = appData.courses;

    // Pre-select first course if not selected yet and courses exist
    if (_selectedCourse == null && coursesList.isNotEmpty) {
      _selectedCourse = coursesList.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Class'),
      ),
      body: SingleChildScrollView(
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
              ],

              // Day Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: _days.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a day';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start & End Time Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectStartTime(context),
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _startTime == null
                            ? 'Start Time'
                            : _startTime!.format(context),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectEndTime(context),
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _endTime == null
                            ? 'End Time'
                            : _endTime!.format(context),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              if (_timeError) ...[
                const SizedBox(height: 8),
                const Text(
                  'Please select both start time and end time.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),

              // Room Input
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed:
                    (coursesList.isEmpty || _selectedCourse == null)
                        ? null
                        : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Add Class',
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
