import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/semester_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/screens/gpa/add_course_grade_screen.dart';
import 'package:uni_partner/utils/gpa_calculator.dart';

class GpaScreen extends StatefulWidget {
  const GpaScreen({super.key});

  @override
  State<GpaScreen> createState() => _GpaScreenState();
}

class _GpaScreenState extends State<GpaScreen> {
  // Target GPA Calculator Controllers & State (local UI state)
  final _targetFormKey = GlobalKey<FormState>();
  final TextEditingController _targetCgpaController = TextEditingController();
  final TextEditingController _futureChController = TextEditingController();
  String? _targetCalculationResult;

  @override
  void dispose() {
    _targetCgpaController.dispose();
    _futureChController.dispose();
    super.dispose();
  }

  void _calculateTargetGpa(double currentCgpa, int completedCreditHours) {
    if (!_targetFormKey.currentState!.validate()) return;

    final targetCgpa = double.tryParse(_targetCgpaController.text.trim());
    final futureCh = int.tryParse(_futureChController.text.trim());

    if (targetCgpa == null || futureCh == null || futureCh <= 0) {
      setState(() {
        _targetCalculationResult = 'Please enter valid numbers.';
      });
      return;
    }

    final currentPoints = currentCgpa * completedCreditHours;
    final targetTotalPoints = targetCgpa * (completedCreditHours + futureCh);
    final requiredFuturePoints = targetTotalPoints - currentPoints;
    final requiredGpa = requiredFuturePoints / futureCh;

    setState(() {
      if (requiredGpa > 4.0) {
        _targetCalculationResult =
            'Target CGPA is not achievable with the entered credit hours.';
      } else if (requiredGpa < 0) {
        _targetCalculationResult = 'You have already exceeded this target.';
      } else {
        _targetCalculationResult =
            'You need approximately ${requiredGpa.toStringAsFixed(2)} GPA in the next $futureCh credit hours.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();

    final currentSemesterCourses = appData.currentSemesterCourses;
    final previousSemesters = appData.previousSemesters;

    // Current Semester Metrics
    final currentGpa = GpaCalculator.calculateGpa(currentSemesterCourses);
    final currentTotalCh =
        GpaCalculator.getTotalCreditHours(currentSemesterCourses);

    // Combine all semesters (previous + current) for CGPA
    final allSemesters = [
      ...previousSemesters,
      SemesterResult(
        id: 'current',
        semesterName: 'Current Semester',
        courses: currentSemesterCourses,
      ),
    ];

    final cgpa = GpaCalculator.calculateCgpa(allSemesters);
    final totalCumulativeCh =
        GpaCalculator.getTotalCreditHoursFromSemesters(allSemesters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA / CGPA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPA & CGPA Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Semester',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentGpa.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currentTotalCh Credit Hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    color: Colors.teal.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cumulative GPA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cgpa.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCumulativeCh Total CH',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Semester Course List
            const Text(
              'Current Semester Courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (currentSemesterCourses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No courses added to current semester.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...currentSemesterCourses.map((course) {
                final gradePoint = GpaCalculator.gradeToPoint(course.grade);

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      course.courseName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${course.creditHours} Credit Hours  |  Grade: ${course.grade}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${gradePoint.toStringAsFixed(2)} pts',
                            style: TextStyle(
                              color: Colors.indigo.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            context
                                .read<AppDataProvider>()
                                .deleteCurrentSemesterCourse(course.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Previous Semesters Section
            const Text(
              'Previous Semesters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...previousSemesters.map((semester) {
              final semGpa = GpaCalculator.calculateGpa(semester.courses);
              final semCh =
                  GpaCalculator.getTotalCreditHours(semester.courses);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    semester.semesterName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'GPA: ${semGpa.toStringAsFixed(2)}  |  $semCh Credit Hours',
                  ),
                  children: semester.courses.map((course) {
                    final gradePoint =
                        GpaCalculator.gradeToPoint(course.grade);

                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(course.courseName),
                      subtitle: Text('${course.creditHours} CH'),
                      trailing: Text(
                        '${course.grade} (${gradePoint.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            const SizedBox(height: 24),

            // GPA Target Calculator Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _targetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GPA Target Calculator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _targetCgpaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Target CGPA (e.g. 3.50)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.track_changes),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter target CGPA';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _futureChController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Expected Future Credit Hours (e.g. 15)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter future credit hours';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _calculateTargetGpa(cgpa, totalCumulativeCh);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Calculate Required GPA'),
                        ),
                      ),
                      if (_targetCalculationResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _targetCalculationResult!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // FloatingActionButton
      floatingActionButton: FloatingActionButton(
        heroTag: 'gpa_fab',
        onPressed: () async {
          final newCourse = await Navigator.push<CourseGrade>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCourseGradeScreen(),
            ),
          );

          if (newCourse != null && mounted) {
            context.read<AppDataProvider>().addCurrentSemesterCourse(newCourse);
          }
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
