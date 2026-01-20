import 'package:flutter/material.dart';
import 'student_layout.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: "Profile",
      child: const Center(
        child: Text(
          "Student Profile Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
