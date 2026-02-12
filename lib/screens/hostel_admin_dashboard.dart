// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../hostel_admin/attendance_report_screen.dart';
import '../main.dart';
import '../hostel_admin/hostel_admin_layout.dart';
import '../hostel_admin/list_students_screen.dart';
import '../hostel_admin/leave_list_screen.dart';
import 'mess_menu_screen.dart';

class HostelAdminDashboard extends StatefulWidget {
  const HostelAdminDashboard({super.key});

  @override
  State<HostelAdminDashboard> createState() => _HostelAdminDashboardState();
}

class _HostelAdminDashboardState extends State<HostelAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final lastWeek = today.subtract(const Duration(days: 7));

    return HostelAdminLayout(
      title: "Dashboard",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ WELCOME TEXT
            const Text(
              "Welcome,",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              "Hostel Admin",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  /// TOTAL STUDENTS
                  _box(
                    context,
                    title: "Total Students",
                    icon: Icons.people,
                    color: appBrown,
                    stream: FirebaseFirestore.instance
                        .collection('student')
                        .snapshots(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListStudentsScreen(),
                        ),
                      );
                    },
                  ),

                  /// PRESENT TODAY
                  _box(
                    context,
                    title: "Present Today",
                    icon: Icons.check_circle,
                    color: Colors.green,
                    stream: FirebaseFirestore.instance
                        .collection('attendance')
                        .where('date', isEqualTo: todayStr)
                        .snapshots(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceReportScreen(),
                        ),
                      );
                    },
                  ),

                  /// LEAVES (7 DAYS)
                  _box(
                    context,
                    title: "Leaves (7 Days)",
                    icon: Icons.assignment,
                    color: Colors.orange,
                    stream: FirebaseFirestore.instance
                        .collection('student_leaves')
                        .where('fromDate', isGreaterThanOrEqualTo: lastWeek)
                        .snapshots(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaveListScreen(),
                        ),
                      );
                    },
                  ),

                  /// MESS MENU
                  _box(
                    context,
                    title: "Mess Menu",
                    icon: Icons.restaurant,
                    color: Colors.blue,
                    stream: FirebaseFirestore.instance
                        .collection('mess_menu')
                        .snapshots(),
                    showCount: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessMenuScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
    required VoidCallback onTap,
    bool showCount = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            showCount
                ? StreamBuilder<QuerySnapshot>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("0");
                      int count = 0;

                      if (snapshot.data!.docs.isNotEmpty) {
                        final doc =
                            snapshot.data!.docs.first.data()
                                as Map<String, dynamic>;

                        if (doc.containsKey('records')) {
                          final records = Map<String, dynamic>.from(
                            doc['records'],
                          );
                          count = records.values.where((v) => v == true).length;
                        } else {
                          count = snapshot.data!.docs.length;
                        }
                      }

                      return Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  )
                : const Text(
                    "View",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ),
    );
  }
}
