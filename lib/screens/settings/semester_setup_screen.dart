import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/semester_settings_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/providers/auth_provider.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class SemesterSetupScreen extends StatefulWidget {
  const SemesterSetupScreen({super.key});

  @override
  State<SemesterSetupScreen> createState() => _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends State<SemesterSetupScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _dateError = false;

  @override
  void initState() {
    super.initState();
    final appData = context.read<AppDataProvider>();
    final settings = appData.semesterSettings;

    if (settings != null) {
      _startDate = settings.startDate;
      _endDate = settings.endDate;
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 120));
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _dateError = false;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 120)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _dateError = false;
      });
    }
  }

  void _submitForm() {
    if (_startDate == null || _endDate == null) {
      setState(() => _dateError = true);
      return;
    }

    final startOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    if (!endOnly.isAfter(startOnly)) {
      setState(() => _dateError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End Date must be after Start Date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newSettings = SemesterSettings(
      startDate: startOnly,
      endDate: endOnly,
    );

    context.read<AppDataProvider>().setSemesterSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semester dates saved.'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentSemesterLabel = auth.currentUser?.semester ?? 'Not Specified';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Dates'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Read-Only Current Semester Banner
            NeoCard(
              backgroundColor: NeoTheme.yellow.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: NeoTheme.stroke),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Semester Label',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          currentSemesterLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: NeoTheme.stroke,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker Card
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semester Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define the official start and end dates of this term.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectStartDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _startDate == null
                                ? 'Start Date'
                                : 'Start: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: NeoTheme.stroke,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectEndDate,
                          icon: const Icon(Icons.event),
                          label: Text(
                            _endDate == null
                                ? 'End Date'
                                : 'End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: NeoTheme.stroke,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_dateError) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Please select valid dates. End Date must be after Start Date.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: NeoTheme.yellow,
                foregroundColor: NeoTheme.stroke,
              ),
              child: const Text(
                'Save Semester Dates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
