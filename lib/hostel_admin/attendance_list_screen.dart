import 'package:flutter/material.dart';
import 'hostel_admin_layout.dart';

class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Attendance",
      child: const Center(child: Text("Attendance Page")),
    );
  }
}
