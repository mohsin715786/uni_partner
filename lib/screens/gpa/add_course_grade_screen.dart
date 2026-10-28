import 'package:flutter/material.dart';
import 'package:uni_partner/models/semester_model.dart';

class AddCourseGradeScreen extends StatefulWidget {
  const AddCourseGradeScreen({super.key});

  @override
  State<AddCourseGradeScreen> createState() => _AddCourseGradeScreenState();
}

class _AddCourseGradeScreenState extends State<AddCourseGradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseController = TextEditingController();

  int _selectedCreditHours = 3;
  String _selectedGrade = 'A';

  final List<int> _creditHourOptions = [1, 2, 3, 4];
  final List<String> _gradeOptions = [
    'A+',
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'F',
  ];

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newCourse = CourseGrade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseName: _courseController.text.trim(),
        creditHours: _selectedCreditHours,
        grade: _selectedGrade,
      );
      Navigator.pop(context, newCourse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Course Grade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCreditHours,
                decoration: const InputDecoration(
                  labelText: 'Credit Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                items: _creditHourOptions.map((int ch) {
                  return DropdownMenuItem<int>(
                    value: ch,
                    child: Text('$ch Credit ${ch == 1 ? 'Hour' : 'Hours'}'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCreditHours = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grade),
                ),
                items: _gradeOptions.map((String grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGrade = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
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
