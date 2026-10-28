import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/firebase_task/firebase_login_screen.dart';
import 'package:uni_partner/providers/auth_provider.dart';
import 'package:uni_partner/screens/attendance/attendance_screen.dart';
import 'package:uni_partner/screens/courses/courses_screen.dart';
import 'package:uni_partner/screens/profile/edit_profile_screen.dart';
import 'package:uni_partner/screens/settings/semester_setup_screen.dart';
import 'package:uni_partner/screens/timetable/timetable_screen.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final auth = context.read<AuthProvider>();
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'S';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: user == null
          ? const Center(
              child: Text('No student profile loaded.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Avatar Header Card
                  NeoCard(
                    backgroundColor: NeoTheme.yellow.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: NeoTheme.yellow,
                          child: Text(
                            _getInitials(user.fullName),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: NeoTheme.stroke,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user.university} • ${user.semester}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: NeoTheme.stroke,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ACADEMIC PROFILE SECTION
                  const Text(
                    'ACADEMIC PROFILE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  NeoCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // 1. Edit Profile
                        ListTile(
                          leading: const Icon(
                            Icons.person_outline,
                            color: NeoTheme.stroke,
                          ),
                          title: const Text(
                            'Edit Profile',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Edit student name, university & semester'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1.5, color: NeoTheme.stroke),

                        // 2. Semester Dates
                        ListTile(
                          leading: const Icon(
                            Icons.date_range_outlined,
                            color: NeoTheme.stroke,
                          ),
                          title: const Text(
                            'Semester Dates',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Set semester start and end dates'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SemesterSetupScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1.5, color: NeoTheme.stroke),

                        // 3. My Courses
                        ListTile(
                          leading: const Icon(
                            Icons.menu_book_outlined,
                            color: NeoTheme.stroke,
                          ),
                          title: const Text(
                            'My Courses',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Add, edit or remove subjects'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoursesScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1.5, color: NeoTheme.stroke),

                        // 4. Timetable
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_month_outlined,
                            color: NeoTheme.stroke,
                          ),
                          title: const Text(
                            'Timetable',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Manage weekly class schedule'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TimetableScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1.5, color: NeoTheme.stroke),

                        // 5. Attendance
                        ListTile(
                          leading: const Icon(
                            Icons.fact_check_outlined,
                            color: NeoTheme.stroke,
                          ),
                          title: const Text(
                            'Attendance',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Update your course attendance'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // UNIVERSITY TASK SECTION
                  const Text(
                    'UNIVERSITY COURSE TASK',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  NeoCard(
                    backgroundColor: NeoTheme.cyan.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(
                        Icons.cloud_outlined,
                        color: NeoTheme.stroke,
                      ),
                      title: const Text(
                        'Firebase Assignment Task',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Course Module — Demo Firebase Auth'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FirebaseLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ACCOUNT SECTION
                  const Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: NeoTheme.pink,
                        foregroundColor: NeoTheme.stroke,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
