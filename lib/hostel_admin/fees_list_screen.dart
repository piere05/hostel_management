// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'hostel_admin_layout.dart';
import 'add_fee_screen.dart';
import 'fee_students_status_screen.dart';

class FeesListScreen extends StatelessWidget {
  const FeesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Fees",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fees')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No fees found"));
          }

          final docs = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 30,
                      headingRowHeight: 56,
                      dataRowHeight: 64,
                      columns: const [
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Title")),
                        DataColumn(label: Text("Amount")),
                        DataColumn(label: Text("Deadline")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final created = (d['createdAt'] as Timestamp).toDate();
                        final deadline = (d['deadline'] as Timestamp).toDate();

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(DateFormat('dd-MM-yyyy').format(created)),
                            ),
                            DataCell(Text(d['title'] ?? "")),
                            DataCell(Text("₹${d['amount']}")),
                            DataCell(
                              Text(DateFormat('dd-MM-yyyy').format(deadline)),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_red_eye,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FeeStudentsStatusScreen(
                                                feeId: doc.id,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddFeeScreen(
                                            docId: doc.id,
                                            data: d,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
