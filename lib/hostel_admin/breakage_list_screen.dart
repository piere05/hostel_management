import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hostel_admin_layout.dart';
import 'add_breakage_screen.dart';

class BreakageListScreen extends StatefulWidget {
  const BreakageListScreen({super.key});

  @override
  State<BreakageListScreen> createState() => _BreakageListScreenState();
}

class _BreakageListScreenState extends State<BreakageListScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Breakage List",
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search name / regno",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v.toLowerCase()),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("breakage")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs.where((d) {
                    final m = d.data() as Map<String, dynamic>;
                    final name = (m['studentName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final reg = (m['regno'] ?? '').toString().toLowerCase();
                    return name.contains(search) || reg.contains(search);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No records"));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("RegNo")),
                        DataColumn(label: Text("Mobile")),
                        DataColumn(label: Text("Amount")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Paid With")),
                        DataColumn(label: Text("Paid Date")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text((m['studentName'] ?? '-').toString()),
                            ),
                            DataCell(Text((m['regno'] ?? '-').toString())),
                            DataCell(Text((m['mobile'] ?? '-').toString())),
                            DataCell(Text((m['amount'] ?? 0).toString())),

                            DataCell(
                              Text(
                                (m['status'] ?? 'not_paid').toString(),
                                style: TextStyle(
                                  color: (m['status'] ?? '') == "paid"
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // ✅ Paid With
                            DataCell(
                              Text(
                                (m['status'] == 'paid')
                                    ? (m['method'] ?? '-').toString()
                                    : '-',
                              ),
                            ),

                            // ✅ Paid Date
                            DataCell(
                              Text(
                                (m['status'] == 'paid' &&
                                        m['updatedAt'] != null)
                                    ? _formatDate(m['updatedAt'])
                                    : '-',
                              ),
                            ),

                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddBreakageScreen(
                                          docId: d.id,
                                          data: m,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => FirebaseFirestore.instance
                                        .collection("breakage")
                                        .doc(d.id)
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
}

String _formatDate(Timestamp t) {
  final d = t.toDate();
  return "${d.day.toString().padLeft(2, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.year}";
}
