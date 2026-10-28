import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/assignment_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/screens/assignments/add_assignments_screen.dart';
import 'package:uni_partner/services/notification_service.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Pending', 'Completed', 'Overdue'];

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return NeoTheme.pink;
      case 'Medium':
        return NeoTheme.orange;
      case 'Low':
        return NeoTheme.mint;
      default:
        return NeoTheme.blue;
    }
  }

  String _getDueMessage(Assignment assignment) {
    if (assignment.isCompleted) return 'Completed';
    if (assignment.isOverdue) return 'Overdue';

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

  void _showDeleteDialog(Assignment assignment) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Assignment?'),
          content: Text(
            'Are you sure you want to delete "${assignment.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final provider = context.read<AppDataProvider>();
                final notifId = NotificationService.instance
                    .getAssignmentNotificationId(assignment.id);
                await NotificationService.instance.cancelNotification(notifId);

                provider.deleteAssignment(assignment.id);
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
    final allAssignments = appData.assignments;

    final filteredAssignments = allAssignments.where((assignment) {
      if (selectedFilter == 'Pending') {
        return !assignment.isCompleted && !assignment.isOverdue;
      } else if (selectedFilter == 'Completed') {
        return assignment.isCompleted;
      } else if (selectedFilter == 'Overdue') {
        return assignment.isOverdue;
      } else {
        return true;
      }
    }).toList();

    filteredAssignments.sort(
      (a, b) => a.dueDate.compareTo(b.dueDate),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
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

          // Assignment List / Empty States
          Expanded(
            child: allAssignments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: NeoTheme.stroke,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No assignments added yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NeoTheme.stroke,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap + to add an assignment.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredAssignments.isEmpty
                    ? Center(
                        child: Text(
                          'No ${selectedFilter.toLowerCase()} assignments.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredAssignments.length,
                        itemBuilder: (context, index) {
                          final assignment = filteredAssignments[index];
                          final priorityColor =
                              _getPriorityColor(assignment.priority);
                          final dueMessage = _getDueMessage(assignment);

                          return NeoCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: assignment.isCompleted,
                                  activeColor: NeoTheme.mint,
                                  checkColor: NeoTheme.stroke,
                                  onChanged: (bool? value) async {
                                    if (value != null) {
                                      final provider =
                                          context.read<AppDataProvider>();
                                      provider.toggleAssignmentCompleted(
                                        assignment.id,
                                        value,
                                      );

                                      final notifId = NotificationService
                                          .instance
                                          .getAssignmentNotificationId(
                                              assignment.id);

                                      if (value == true) {
                                        await NotificationService.instance
                                            .cancelNotification(notifId);
                                      } else {
                                        if (!assignment.isOverdue) {
                                          await NotificationService.instance
                                              .scheduleAssignmentReminder(
                                            id: notifId,
                                            assignmentTitle: assignment.title,
                                            courseName: assignment.courseName,
                                            dueDate: assignment.dueDate,
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment.title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          decoration: assignment.isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: assignment.isCompleted
                                              ? Colors.grey
                                              : NeoTheme.stroke,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        assignment.courseName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: NeoTheme.stroke,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dueMessage,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: assignment.isOverdue
                                                  ? Colors.red
                                                  : assignment.isCompleted
                                                      ? Colors.green.shade800
                                                      : NeoTheme.stroke,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: priorityColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: NeoTheme.stroke,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              assignment.priority,
                                              style: const TextStyle(
                                                color: NeoTheme.stroke,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _showDeleteDialog(assignment);
                                  },
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
        heroTag: 'assignment_fab',
        onPressed: () async {
          final provider = context.read<AppDataProvider>();
          final newAssignment = await Navigator.push<Assignment>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAssignmentScreen(),
            ),
          );

          if (newAssignment != null) {
            provider.addAssignment(newAssignment);

            if (!newAssignment.isCompleted && !newAssignment.isOverdue) {
              final notifId = NotificationService.instance
                  .getAssignmentNotificationId(newAssignment.id);
              await NotificationService.instance.scheduleAssignmentReminder(
                id: notifId,
                assignmentTitle: newAssignment.title,
                courseName: newAssignment.courseName,
                dueDate: newAssignment.dueDate,
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
