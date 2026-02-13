import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'student_layout.dart';
import 'register_complaint_screen.dart';

class StudentComplaintListScreen extends StatelessWidget {
  const StudentComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser!.email;

    return StudentLayout(
      title: "My Complaints",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('student_complaints')
            .where('addedBy', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints found"));
          }

          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("S.No")),
                DataColumn(label: Text("Room")),
                DataColumn(label: Text("Department")),
                DataColumn(label: Text("Mobile")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Remarks")),
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Action")),
              ],
              rows: List.generate(docs.length, (i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;

                return DataRow(
                  cells: [
                    DataCell(Text("${i + 1}")),
                    DataCell(Text(data['roomNo'] ?? "")),
                    DataCell(Text(data['department'] ?? "")),
                    DataCell(Text(data['mobile'] ?? "")),
                    DataCell(
                      Text(
                        data['status'] ?? "",
                        style: TextStyle(
                          color: data['status'] == "Pending"
                              ? Colors.orange
                              : data['status'] == "Resolved"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(Text(data['adminRemark'] ?? " - ")),
                    DataCell(
                      Text(
                        DateFormat(
                          'dd-MM-yyyy',
                        ).format((data['createdAt'] as Timestamp).toDate()),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          // ✅ EDIT ONLY IF PENDING
                          if (data['status'] == 'Pending')
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterComplaintScreen(
                                      docId: d.id,
                                      data: data,
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
                                    "Are you sure you want to delete this complaint?",
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
