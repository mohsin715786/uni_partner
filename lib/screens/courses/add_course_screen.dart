import 'package:flutter/material.dart';
import 'package:uni_partner/models/course_model.dart';

class AddCourseScreen extends StatefulWidget {
  final Course? courseToEdit;

  const AddCourseScreen({super.key, this.courseToEdit});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _creditController;
  late TextEditingController _instructorController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.courseToEdit?.courseName ?? '');
    _codeController =
        TextEditingController(text: widget.courseToEdit?.courseCode ?? '');
    _creditController = TextEditingController(
        text: widget.courseToEdit != null
            ? widget.courseToEdit!.creditHours.toString()
            : '3');
    _instructorController =
        TextEditingController(text: widget.courseToEdit?.instructor ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _creditController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final credits = int.parse(_creditController.text.trim());
    final instructor = _instructorController.text.trim();

    final course = Course(
      id: widget.courseToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      courseName: name,
      courseCode: code,
      creditHours: credits,
      instructor: instructor,
    );

    Navigator.pop(context, course);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.courseToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Course' : 'Add Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Course Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code (e.g. CS-305)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Credit Hours
              TextFormField(
                controller: _creditController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credit Hours (1 - 6)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter credit hours';
                  }
                  final credits = int.tryParse(value.trim());
                  if (credits == null || credits < 1 || credits > 6) {
                    return 'Credit hours must be an integer between 1 and 6';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Instructor (Optional)
              TextFormField(
                controller: _instructorController,
                decoration: const InputDecoration(
                  labelText: 'Instructor Name (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isEditing ? 'Update Course' : 'Add Course',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
