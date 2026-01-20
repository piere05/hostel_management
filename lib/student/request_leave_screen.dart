import 'package:flutter/material.dart';
import 'student_layout.dart';

class RequestLeaveScreen extends StatelessWidget {
  const RequestLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: "Request Leave",
      child: const Center(
        child: Text(
          "Request Leave Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
