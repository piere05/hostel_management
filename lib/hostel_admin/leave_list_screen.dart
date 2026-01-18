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
                hintText: "Search by name / regno",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // 📊 DATA TABLE
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("leaves")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['studentName']
                            .toString()
                            .toLowerCase()
                            .contains(search) ||
                        data['regno']
                            .toString()
                            .toLowerCase()
                            .contains(search);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No records found"));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Reg No")),
                        DataColumn(label: Text("From")),
                        DataColumn(label: Text("To")),
                        DataColumn(label: Text("Days")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;

                        return DataRow(cells: [
                          DataCell(Text(d['studentName'])),
                          DataCell(Text(d['regno'])),
                          DataCell(Text(_fmt(d['fromDate']))),
                          DataCell(Text(_fmt(d['toDate']))),
                          DataCell(Text(d['days'].toString())),
                          DataCell(Text(
                            d['status'],
                            style: TextStyle(
                              color: d['status'] == 'approved'
                                  ? Colors.green
                                  : d['status'] == 'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _actionDialog(context, doc.id, d),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => FirebaseFirestore.instance
                                    .collection("leaves")
                                    .doc(doc.id)
                                    .delete(),
                              ),
                            ],
                          )),
                        ]);
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
          decoration: const InputDecoration(labelText: "Reason"),
        ),
        actions: [
          TextButton(
            child: const Text("Reject"),
            onPressed: () async {
              await _updateLeave(
                  docId, "rejected", remarkCtrl.text, data);
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            child: const Text("Approve"),
            onPressed: () async {
              await _updateLeave(
                  docId, "approved", remarkCtrl.text, data);
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
    await FirebaseFirestore.instance.collection("leaves").doc(id).update({
      "status": status,
      "adminRemark": remark,
    });

    await FirebaseFirestore.instance.collection("notifications").add({
      "to": data['email'],
      "title":
          status == "approved" ? "Leave Approved" : "Leave Rejected",
      "message":
          "Your leave (${_fmt(data['fromDate'])} - ${_fmt(data['toDate'])}) is $status.\n$remark",
      "createdAt": Timestamp.now(),
      "read": false,
    });
  }

  String _fmt(Timestamp t) {
    final d = t.toDate();
    return "${d.day}-${d.month}-${d.year}";
  }
}
