import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/providers/auth_provider.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _universityController;
  late TextEditingController _departmentController;
  late TextEditingController _semesterController;
  late String _email;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _universityController =
        TextEditingController(text: user?.university ?? '');
    _departmentController =
        TextEditingController(text: user?.department ?? '');
    _semesterController = TextEditingController(text: user?.semester ?? '');
    _email = user?.email ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final auth = context.read<AuthProvider>();
    await auth.updateUserProfile(
      fullName: _fullNameController.text,
      university: _universityController.text,
      department: _departmentController.text,
      semester: _semesterController.text,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated.'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeoCard(
                child: Column(
                  children: [
                    // Email (Read-only)
                    TextFormField(
                      initialValue: _email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Read-Only)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // University
                    TextFormField(
                      controller: _universityController,
                      decoration: const InputDecoration(
                        labelText: 'University Name',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter university name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Department
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.domain_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Current Semester
                    TextFormField(
                      controller: _semesterController,
                      decoration: const InputDecoration(
                        labelText: 'Current Semester',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter current semester';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: NeoTheme.yellow,
                  foregroundColor: NeoTheme.stroke,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: NeoTheme.stroke,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Profile Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
