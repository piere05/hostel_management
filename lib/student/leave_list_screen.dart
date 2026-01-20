import 'package:flutter/material.dart';
import 'student_layout.dart';

class StudentLeaveListScreen extends StatelessWidget {
  const StudentLeaveListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: "My Leaves",
      child: const Center(
        child: Text(
          "Leave List Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
