import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login page/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Bus Tracking',
      theme: ThemeData(
        // Updated to use colorScheme for Material 3 compatibility
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Blue[900]
          primary: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
      ),
      // AuthWrapper serves as the persistent gatekeeper
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listens to the Firebase Auth session state
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Show a loading spinner while Firebase initializes the session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
            ),
          );
        }

        // 2. If the user is logged in (session exists)
        if (snapshot.hasData) {
          // Because your app requires an OTP *after* Firebase Auth signs in,
          // the user will land back on the LoginScreen to start a fresh OTP flow
          // if the app was fully killed/cleared from memory.
          return const LoginScreen();
        }

        // 3. If no session exists (or user logged out), show Login Screen
        return const LoginScreen();
      },
    );
  }
}