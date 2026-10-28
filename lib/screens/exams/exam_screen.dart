import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/exam_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/screens/exams/add_exam_screen.dart';
import 'package:uni_partner/services/notification_service.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  String selectedFilter = 'Upcoming';

  final List<String> filters = ['Upcoming', 'Past', 'All'];

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

  String _formatDate(DateTime dt) {
    final monthStr = _months[dt.month - 1];
    return '$monthStr ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $period';
  }

  String _getExamCountdown(DateTime examDateTime) {
    if (examDateTime.isBefore(DateTime.now())) {
      return 'Completed / Past';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay =
        DateTime(examDateTime.year, examDateTime.month, examDateTime.day);

    final differenceInDays = examDay.difference(today).inDays;

    if (differenceInDays == 0) {
      return 'Today';
    } else if (differenceInDays == 1) {
      return 'Tomorrow';
    } else if (differenceInDays < 14) {
      return 'In $differenceInDays Days';
    } else {
      final weeks = (differenceInDays / 7).round();
      return 'In $weeks Weeks';
    }
  }

  void _showDeleteDialog(Exam exam) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Exam?'),
          content: Text(
            'Are you sure you want to delete ${exam.courseName} (${exam.examTitle})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final provider = context.read<AppDataProvider>();
                final int notifId = NotificationService.instance
                    .getExamNotificationId(exam.id);
                await NotificationService.instance.cancelNotification(notifId);

                provider.deleteExam(exam.id);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();
    final allExams = appData.exams;

    final filteredExams = allExams.where((exam) {
      if (selectedFilter == 'Upcoming') {
        return !exam.isPast;
      } else if (selectedFilter == 'Past') {
        return exam.isPast;
      } else {
        return true;
      }
    }).toList();

    filteredExams.sort((a, b) => a.examDateTime.compareTo(b.examDateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = filter == selectedFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: NeoTheme.yellow,
                    labelStyle: TextStyle(
                      color: NeoTheme.stroke,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.bold,
                    ),
                    side: const BorderSide(color: NeoTheme.stroke, width: 2),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 2, thickness: 2, color: NeoTheme.stroke),

          // Exam List / Empty States
          Expanded(
            child: allExams.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: NeoTheme.stroke,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No exams scheduled yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NeoTheme.stroke,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap + to add an upcoming exam.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredExams.isEmpty
                    ? Center(
                        child: Text(
                          'No ${selectedFilter.toLowerCase()} exams.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredExams.length,
                        itemBuilder: (context, index) {
                          final exam = filteredExams[index];
                          final countdownText =
                              _getExamCountdown(exam.examDateTime);

                          return NeoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exam.courseName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: exam.isPast
                                            ? Colors.grey.shade200
                                            : NeoTheme.pink,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: NeoTheme.stroke,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        countdownText,
                                        style: const TextStyle(
                                          color: NeoTheme.stroke,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exam.examTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: NeoTheme.stroke,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(exam.examDateTime),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: NeoTheme.stroke,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTime(exam.examDateTime),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: NeoTheme.stroke,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Room ${exam.room}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _showDeleteDialog(exam);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'exam_fab',
        onPressed: () async {
          final provider = context.read<AppDataProvider>();
          final newExam = await Navigator.push<Exam>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExamScreen(),
            ),
          );

          if (newExam != null) {
            provider.addExam(newExam);

            final int notifId = NotificationService.instance
                .getExamNotificationId(newExam.id);
            await NotificationService.instance.scheduleExamReminder(
              id: notifId,
              courseName: newExam.courseName,
              examTitle: newExam.examTitle,
              examDateTime: newExam.examDateTime,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
