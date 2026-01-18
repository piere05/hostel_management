import 'dart:convert';
import 'package:flutter/material.dart';
import 'hostel_admin_layout.dart';

class ViewStudentScreen extends StatelessWidget {
  final Map<String, dynamic> d;

  const ViewStudentScreen({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Student Details",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                if (d["profileImageBase64"] != null)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          MemoryImage(base64Decode(d["profileImageBase64"])),
                    ),
                  ),
                const SizedBox(height: 16),
                _row("Name", d["name"]),
                _row("Reg No", d["regno"]),
                _row("Email", d["email"]),
                _row("Mobile", d["mobile"]),
                _row("Parent", d["parentMobile"]),
                _row("Course", d["course"]),
                _row("Department", d["department"]),
                _row("Year", d["year"]),
                _row("Duration", d["duration"]),
                _row("Address", d["address"]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text("$k : $v"),
    );
  }
}
