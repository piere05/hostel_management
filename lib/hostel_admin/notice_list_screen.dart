import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_notice_screen.dart';
import 'hostel_admin_layout.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Notices",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notices")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No notices found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              final d = snap.data!.docs[index];
              final m = d.data() as Map<String, dynamic>;

              final title = (m['title'] ?? '-').toString();
              final desc = (m['description'] ?? '').toString();
              final img = (m['imageBase64'] ?? '').toString();

              final createdAt = m['createdAt'] != null
                  ? (m['createdAt'] as Timestamp).toDate()
                  : null;

              final dateText = createdAt != null
                  ? "${createdAt.day}-${createdAt.month}-${createdAt.year}"
                  : "-";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// IMAGE
                      img.isNotEmpty
                          ? Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: MemoryImage(base64Decode(img)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : const Text(""),

                      const SizedBox(height: 10),

                      /// TITLE
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// DESCRIPTION
                      Text(desc),

                      const SizedBox(height: 8),

                      /// DATE
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// ACTIONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddNoticeScreen(docId: d.id, data: m),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("notices")
                                  .doc(d.id)
                                  .delete();
                            },
                          ),
                        ],
                      ),
                    ],
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
