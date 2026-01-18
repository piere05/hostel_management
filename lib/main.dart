import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/hostel_admin_dashboard.dart';
import 'screens/mess_admin_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


const Color appBrown = Color.fromARGB(255, 124, 62, 3);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HostelApp());
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hostel Management',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: appBrown,
        appBarTheme: const AppBarTheme(
          backgroundColor: appBrown,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appBrown,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // 🔥 THIS IS THE KEY FIX
      home: const AuthGate(),
    );
  }
}

/// 🔐 AuthGate decides where to go
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // NOT LOGGED IN
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final email = snapshot.data!.email ?? "";

        // HOSTEL ADMIN
        if (email == "hostel@gmail.com") {
          return const HostelAdminDashboard();
        }

        // MESS ADMIN
        if (email == "mess@gmail.com") {
          return const MessAdminDashboard();
        }

        // STUDENT CHECK
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("student")
              .where("email", isEqualTo: email)
              .limit(1)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // STUDENT FOUND
            if (snap.hasData && snap.data!.docs.isNotEmpty) {
              return const StudentDashboard();
            }

            // NOT STUDENT → LOGOUT
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
        );
      },
    );
  }
}
