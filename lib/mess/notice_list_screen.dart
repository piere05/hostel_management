// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'mess_layout.dart';
import 'add_notice_screen.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MessLayout(
      title: "Notices",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('createdBy', isEqualTo: 'Mess Admin')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notices found"));
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
                        DataColumn(label: Text("Description")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final ts = data['createdAt'] as Timestamp?;
                        final date = ts == null
                            ? "-"
                            : DateFormat('dd-MM-yyyy').format(ts.toDate());

                        return DataRow(
                          cells: [
                            DataCell(Text(date)),
                            DataCell(Text(data['title'] ?? "")),
                            DataCell(
                              SizedBox(
                                width: 350,
                                child: Text(
                                  data['description'] ?? "",
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddNoticeScreen(
                                            editId: doc.id,
                                            editTitle: data['title'],
                                            editDesc: data['description'],
                                            editSendPush:
                                                data['sendPush'] ?? true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, doc.id),
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

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Notice"),
        content: const Text("Are you sure you want to delete this notice?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('notices')
                  .doc(id)
                  .delete();

              Navigator.pop(dialogContext); // ✅ CLOSES DIALOG PROPERLY
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
