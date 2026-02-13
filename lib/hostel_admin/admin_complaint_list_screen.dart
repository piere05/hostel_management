// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hostel_admin_layout.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Student Complaints",
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

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("student_complaints")
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

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final email = (data['addedBy'] ?? "")
                        .toString()
                        .toLowerCase();
                    return email.contains(search);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No complaints found"));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Dept")),
                        DataColumn(label: Text("Year")),
                        DataColumn(label: Text("Mobile")),
                        DataColumn(label: Text("Room")),
                        DataColumn(label: Text("Description")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final status = (d['status'] ?? 'Pending').toString();

                        return DataRow(
                          cells: [
                            DataCell(Text(d['name'] ?? "")),
                            DataCell(Text(d['addedBy'] ?? "")),
                            DataCell(Text(d['department'] ?? "")),
                            DataCell(Text(d['year'] ?? "")),
                            DataCell(Text(d['mobile'] ?? "")),
                            DataCell(Text(d['roomNo'] ?? "")),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  d['description'] ?? "",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == "Resolved"
                                      ? Colors.green
                                      : status == "Rejected"
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
                                    onPressed: status == "Pending"
                                        ? () =>
                                              _actionDialog(context, doc.id, d)
                                        : null,
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

  // ===== ACTION DIALOG =====
  void _actionDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Complaint Status"),
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
              await _updateComplaint(docId, "Rejected", remarkCtrl.text, data);
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            child: const Text("Resolve"),
            onPressed: () async {
              await _updateComplaint(docId, "Resolved", remarkCtrl.text, data);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateComplaint(
    String id,
    String status,
    String remark,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance
        .collection("student_complaints")
        .doc(id)
        .update({
          "status": status,
          "adminRemark": remark,
          "actionAt": Timestamp.now(),
        });

    // 🔔 Notification
    await FirebaseFirestore.instance.collection("notifications").add({
      "to": (data['addedBy'] ?? "").toString(),
      "title": "Complaint $status",
      "message":
          "Your complaint regarding room ${data['roomNo']} has been $status.\n$remark",
      "createdAt": Timestamp.now(),
      "read": false,
    });
  }
}
