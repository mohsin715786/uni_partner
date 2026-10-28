import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_partner/providers/app_data_provider.dart';
import 'package:uni_partner/providers/auth_provider.dart';
import 'package:uni_partner/screens/auth/login_screen.dart';
import 'package:uni_partner/screens/main_screen.dart';
import 'package:uni_partner/screens/onboarding/first_time_setup_screen.dart';
import 'package:uni_partner/services/notification_service.dart';
import 'package:uni_partner/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for native Android google-services.json configuration
  await Firebase.initializeApp();
  debugPrint('Firebase initialized: ${Firebase.apps.map((e) => e.name).toList()}');

  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const UniPartnerApp(),
    ),
  );
}

class UniPartnerApp extends StatelessWidget {
  const UniPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniPartner',
      theme: NeoTheme.themeData,
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Loading State while restoring session from SharedPreferences
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Auth Gate Logic
          if (!auth.isLoggedIn) {
            return const LoginScreen();
          }

          if (!auth.isInitialSetupCompleted) {
            return const FirstTimeSetupScreen();
          }

          return const MainScreen();
        },
      ),
    );
  }
}
