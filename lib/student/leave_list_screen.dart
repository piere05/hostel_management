import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'student_layout.dart';
import 'request_leave_screen.dart';

class StudentLeaveListScreen extends StatelessWidget {
  const StudentLeaveListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser!.email;

    return StudentLayout(
      title: "My Leave Requests",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('student_leaves')
            .where('studentEmail', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔴 ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 🔵 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🟡 EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No leave requests"));
          }

          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("S.No")),
                DataColumn(label: Text("From")),
                DataColumn(label: Text("To")),
                DataColumn(label: Text("Days")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Action")),
              ],
              rows: List.generate(docs.length, (i) {
                final d = docs[i];
                return DataRow(
                  cells: [
                    DataCell(Text("${i + 1}")),
                    DataCell(
                      Text(
                        DateFormat('dd-MM-yyyy').format(d['fromDate'].toDate()),
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat('dd-MM-yyyy').format(d['toDate'].toDate()),
                      ),
                    ),
                    DataCell(Text(d['totalDays'].toString())),
                    DataCell(Text(d['status'])),
                    DataCell(
                      Row(
                        children: [
                          if (d['status'] == 'Pending')
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RequestLeaveScreen(
                                      docId: d.id,
                                      data: d.data() as Map<String, dynamic>,
                                    ),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Confirm Delete"),
                                  content: const Text(
                                    "Are you sure you want to delete this leave?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await d.reference.delete();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
