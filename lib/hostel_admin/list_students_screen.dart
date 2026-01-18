import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'hostel_admin_layout.dart';
import 'add_student_screen.dart';
import 'view_student_screen.dart';

class ListStudentsScreen extends StatefulWidget {
  const ListStudentsScreen({super.key});

  @override
  State<ListStudentsScreen> createState() => _ListStudentsScreenState();
}

class _ListStudentsScreenState extends State<ListStudentsScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Students",
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("student")
                  .snapshots(),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = s.data!.docs.where((d) {
                  return d["name"]
                          .toString()
                          .toLowerCase()
                          .contains(search) ||
                      d["regno"]
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
                      DataColumn(label: Text("S.No")),
                      DataColumn(label: Text("Reg No")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Mobile")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: List.generate(docs.length, (i) {
                      final d = docs[i];
                      return DataRow(cells: [
                        DataCell(Text("${i + 1}")),
                        DataCell(Text(d["regno"])),
                        DataCell(Text(d["name"])),
                        DataCell(Text(d["mobile"])),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ViewStudentScreen(d: d.data() as Map<String, dynamic>),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddStudentScreen(
                                    studentData:
                                        d.data() as Map<String, dynamic>,
                                    docId: d.id,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("student")
                                    .doc(d.id)
                                    .delete();
                              },
                            ),
                          ],
                        )),
                      ]);
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
