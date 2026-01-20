import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../screens/login_screen.dart';
import '../screens/student_dashboard.dart';

// placeholders – we’ll build these later
import 'request_leave_screen.dart';
import 'leave_list_screen.dart';
import 'student_profile_screen.dart';
import 'student_notification_screen.dart';

class StudentLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const StudentLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
  int _currentIndex = 0;

  String studentName = "";

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

Future<void> _loadStudentName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('student')
      .where('email', isEqualTo: user.email)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty && mounted) {
    setState(() {
      studentName = snapshot.docs.first['name'];
    });
  }
}



  // 🔐 Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _go(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      // ================= DRAWER =================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: appBrown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
  studentName.isEmpty ? "Hi 👋" : "Hi, $studentName",
  style: const TextStyle(
    color: Colors.white,
    fontSize: 18,
  ),
),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                _go(const StudentDashboard());
              },
            ),

            ExpansionPanelList.radio(
              children: [
                ExpansionPanelRadio(
                  value: "leave",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.assignment),
                    title: Text("Manage Leave"),
                  ),
                  body: Column(
                    children: [
                      _sub(
                        "Request Leave",
                        () => _go(const RequestLeaveScreen()),
                      ),
                      _sub(
                        "List Leaves",
                        () => _go(const StudentLeaveListScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: widget.child,

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: appBrown,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 0) {
            _go(const StudentDashboard());
          } else if (index == 1) {
            _go(const StudentNotificationScreen());
          } else if (index == 2) {
            _go(const StudentProfileScreen());
          } else if (index == 3) {
            _logout();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notification",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Logout",
          ),
        ],
      ),
    );
  }

  Widget _sub(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
