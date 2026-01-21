// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'mess_layout.dart';
import 'add_menu_screen.dart';

class MenuListScreen extends StatelessWidget {
  const MenuListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MessLayout(
      title: "Mess Menu",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mess_menu')
            .orderBy('day')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No menu added yet"));
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
                      columnSpacing: 40,
                      headingRowHeight: 56,
                      dataRowHeight: 60,
                      columns: const [
                        DataColumn(label: Text("Day")),
                        DataColumn(label: Text("Menu")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return DataRow(
                          cells: [
                            DataCell(Text(data['day'])),
                            DataCell(
                              SizedBox(width: 400, child: Text(data['menu'])),
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
                                          builder: (_) => AddMenuScreen(
                                            editDay: data['day'],
                                            editMenu: data['menu'],
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

  void _confirmDelete(BuildContext context, String day) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Menu"),
        content: Text("Delete menu for $day?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('mess_menu')
                  .doc(day)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
