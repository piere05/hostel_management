import 'package:flutter/material.dart';
import 'student_layout.dart';

class StudentNotificationScreen extends StatelessWidget {
  const StudentNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: "Notifications",
      child: const Center(
        child: Text(
          "Student Notification Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
