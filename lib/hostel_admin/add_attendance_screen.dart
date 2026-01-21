// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hostel_admin_layout.dart';

class AddAttendanceScreen extends StatefulWidget {
  const AddAttendanceScreen({super.key});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, bool> attendance = {};

  String get dateId =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final doc = await FirebaseFirestore.instance
        .collection("attendance")
        .doc(dateId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final Map<String, dynamic> records = data['records'];
      setState(() {
        attendance = records.map((k, v) => MapEntry(k, v as bool));
      });
    }
  }

  Future<void> _saveAttendance() async {
    await FirebaseFirestore.instance.collection("attendance").doc(dateId).set({
      "date": dateId,
      "records": attendance,
      "createdAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Attendance saved")));
  }

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Add Attendance",
      child: Column(
        children: [
          /// DATE PICKER
          ListTile(
            title: Text("Date: $dateId"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: selectedDate,
              );
              if (d != null) {
                setState(() {
                  selectedDate = d;
                  attendance.clear();
                });
                _loadAttendance();
              }
            },
          ),

          const Divider(),

          /// STUDENT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("student")
                  .orderBy("name")
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snap.data!.docs.map((d) {
                    final s = d.data() as Map<String, dynamic>;
                    final regno = s['regno'];

                    return CheckboxListTile(
                      title: Text(s['name']),
                      subtitle: Text(regno),
                      value: attendance[regno] ?? false,
                      onChanged: (v) {
                        setState(() {
                          attendance[regno] = v ?? false;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveAttendance,
                child: const Text("SAVE ATTENDANCE"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
