import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/models/timetable_model.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/screens/timetable/add_class_screen.dart';
import 'package:uni_partner/services/notification_service.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String selectedDay = 'Monday';

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppDataProvider>();

    final filteredEntries = appData.timetableEntries
        .where((entry) => entry.day == selectedDay)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day == selectedDay;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(day),
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
                          selectedDay = day;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 2, thickness: 2, color: NeoTheme.stroke),
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(
                    child: Text(
                      'No classes scheduled for this day.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];

                      return NeoCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.courseName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        size: 16,
                                        color: NeoTheme.stroke,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${entry.startTime} - ${entry.endTime}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: NeoTheme.stroke,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Room ${entry.room}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
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
                              onPressed: () async {
                                final provider =
                                    context.read<AppDataProvider>();
                                final notifId = NotificationService.instance
                                    .getClassNotificationId(entry.id);
                                await NotificationService.instance
                                    .cancelNotification(notifId);

                                provider.deleteTimetableEntry(entry.id);
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
        heroTag: 'timetable_fab',
        onPressed: () async {
          final provider = context.read<AppDataProvider>();
          final newEntry = await Navigator.push<TimetableEntry>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddClassScreen(),
            ),
          );

          if (newEntry != null) {
            provider.addTimetableEntry(newEntry);

            final notifId = NotificationService.instance
                .getClassNotificationId(newEntry.id);
            await NotificationService.instance.scheduleClassReminder(
              id: notifId,
              courseName: newEntry.courseName,
              day: newEntry.day,
              startTime: newEntry.startTime,
              room: newEntry.room,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
