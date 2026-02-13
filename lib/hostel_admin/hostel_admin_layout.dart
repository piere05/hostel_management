import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../screens/login_screen.dart';
import '../screens/hostel_admin_dashboard.dart';

import 'add_attendance_screen.dart';
import 'add_fee_screen.dart';
import 'add_notice_screen.dart';
import 'add_student_screen.dart';
import 'admin_complaint_list_screen.dart';
import 'attendance_report_screen.dart';
import 'fees_list_screen.dart';
import 'hostel_notification.dart';
import 'list_students_screen.dart';
import 'add_breakage_screen.dart';
import 'breakage_list_screen.dart';
import 'leave_list_screen.dart';
import 'notice_list_screen.dart';

class HostelAdminLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const HostelAdminLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<HostelAdminLayout> createState() => _HostelAdminLayoutState();
}

class _HostelAdminLayoutState extends State<HostelAdminLayout> {
  int _currentIndex = 0;

  // 🔐 LOGOUT (FINAL & CORRECT)
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _go(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
              child: const Text(
                "Hostel Admin",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
                _go(const HostelAdminDashboard());
              },
            ),

            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Manage Leave"),
              onTap: () {
                Navigator.pop(context);
                _go(const LeaveListScreen());
              },
            ),

            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Manage Complaints"),
              onTap: () {
                Navigator.pop(context);
                _go(const ComplaintListScreen());
              },
            ),
            ExpansionPanelList.radio(
              children: [
                ExpansionPanelRadio(
                  value: "students",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.people),
                    title: Text("Manage Student"),
                  ),
                  body: Column(
                    children: [
                      _sub("Add Student", () => _go(const AddStudentScreen())),
                      _sub(
                        "List Students",
                        () => _go(const ListStudentsScreen()),
                      ),
                    ],
                  ),
                ),

                ExpansionPanelRadio(
                  value: "breakage",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.warning),
                    title: Text("Manage Breakage"),
                  ),
                  body: Column(
                    children: [
                      _sub(
                        "Add Breakage",
                        () => _go(const AddBreakageScreen()),
                      ),
                      _sub(
                        "Breakage List",
                        () => _go(const BreakageListScreen()),
                      ),
                    ],
                  ),
                ),

                ExpansionPanelRadio(
                  value: "notice",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text("Manage Notices"),
                  ),
                  body: Column(
                    children: [
                      _sub("Add Notice ", () => _go(const AddNoticeScreen())),
                      _sub("List Notice ", () => _go(const NoticeListScreen())),
                    ],
                  ),
                ),

                ExpansionPanelRadio(
                  value: "fees",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.currency_rupee_sharp),
                    title: Text("Manage Fees"),
                  ),
                  body: Column(
                    children: [
                      _sub("Add Fees ", () => _go(const AddFeeScreen())),
                      _sub("List Fees ", () => _go(const FeesListScreen())),
                    ],
                  ),
                ),

                ExpansionPanelRadio(
                  value: "attendance",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.event_available),
                    title: Text("Manage Attendance"),
                  ),
                  body: Column(
                    children: [
                      _sub(
                        "Add Attendance",
                        () => _go(const AddAttendanceScreen()),
                      ),
                      _sub(
                        "List Attendance",
                        () => _go(const AttendanceReportScreen()),
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
            _go(const HostelAdminDashboard());
          } else if (index == 1) {
            _go(const hostel_admin_notification_screen());
          } else if (index == 2) {
            _go(const BreakageListScreen());
          } else if (index == 3) {
            _logout();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Breakage"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
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
