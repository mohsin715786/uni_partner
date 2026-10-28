import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uni_partner/firebase_task/firebase_auth_service.dart';
import 'package:uni_partner/firebase_task/firebase_login_screen.dart';
import 'package:uni_partner/utils/theme.dart';
import 'package:uni_partner/widgets/neo_card.dart';

class FirebaseHomeScreen extends StatelessWidget {
  const FirebaseHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Task Success'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Firebase Login Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'University Assignment Task Module',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            NeoCard(
              backgroundColor: NeoTheme.mint.withValues(alpha: 0.3),
              child: Column(
                children: [
                  const Text(
                    'Authenticated Firebase User:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No User Email',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UID: ${user?.uid ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FirebaseLoginScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout from Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoTheme.pink,
                foregroundColor: NeoTheme.stroke,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
