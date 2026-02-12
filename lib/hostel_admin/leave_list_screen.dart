// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hostel_admin_layout.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Leave Requests",
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 SEARCH
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search by email",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // 📊 DATA TABLE
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("student_leaves")
                    .snapshots(), // ❌ no orderBy (no index)
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final email = (data['studentEmail'] ?? "")
                        .toString()
                        .toLowerCase();

                    return email.contains(search);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No leave requests"));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("From")),
                        DataColumn(label: Text("To")),
                        DataColumn(label: Text("Days")),
                        DataColumn(label: Text("Reason")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;

                        final status = (d['status'] ?? 'Pending').toString();

                        return DataRow(
                          cells: [
                            DataCell(Text((d['studentName'] ?? '').toString())),
                            DataCell(
                              Text((d['studentEmail'] ?? '').toString()),
                            ),
                            DataCell(Text(_fmt(d['fromDate']))),
                            DataCell(Text(_fmt(d['toDate']))),
                            DataCell(Text((d['totalDays'] ?? 0).toString())),
                            DataCell(Text((d['reason']))),
                            DataCell(
                              Text(
                                status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Approved'
                                      ? Colors.green
                                      : status == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color.fromARGB(255, 76, 111, 175),
                                    ),
                                    onPressed: status == 'Pending'
                                        ? () =>
                                              _actionDialog(context, doc.id, d)
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => FirebaseFirestore.instance
                                        .collection("student_leaves")
                                        .doc(doc.id)
                                        .delete(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== APPROVE / REJECT =====
  void _actionDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Approve / Reject Leave"),
        content: TextField(
          controller: remarkCtrl,
          decoration: const InputDecoration(
            labelText: "Admin Remark (optional)",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Reject"),
            onPressed: () async {
              await _updateLeave(docId, "Rejected", remarkCtrl.text, data);
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            child: const Text("Approve"),
            onPressed: () async {
              await _updateLeave(docId, "Approved", remarkCtrl.text, data);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateLeave(
    String id,
    String status,
    String remark,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance
        .collection("student_leaves")
        .doc(id)
        .update({
          "status": status,
          "adminRemark": remark,
          "actionAt": Timestamp.now(),
        });

    // 🔔 Notification (safe)
    await FirebaseFirestore.instance.collection("notifications").add({
      "to": (data['studentEmail'] ?? '').toString(),
      "title": "Leave $status",
      "message":
          "Your leave (${_fmt(data['fromDate'])} - ${_fmt(data['toDate'])}) has been $status.\n$remark",
      "createdAt": Timestamp.now(),
      "read": false,
    });
  }

  String _fmt(dynamic t) {
    if (t == null) return "-";
    final d = (t as Timestamp).toDate();
    return "${d.day}-${d.month}-${d.year}";
  }
}
