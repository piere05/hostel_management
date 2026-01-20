import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/hostel_admin_dashboard.dart';
import 'screens/mess_admin_dashboard.dart';

const Color appBrown = Color.fromARGB(255, 124, 62, 3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ CORRECT INITIALIZATION
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
  } else {
    await Firebase.initializeApp(); // ANDROID
  }

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

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final email = snapshot.data!.email ?? "";

        if (email == "hostel@gmail.com") {
          return const HostelAdminDashboard();
        }

        if (email == "mess@gmail.com") {
          return const MessDashboard();
        }

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

            if (snap.hasData && snap.data!.docs.isNotEmpty) {
              return const StudentDashboard();
            }

            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
        );
      },
    );
  }
}
