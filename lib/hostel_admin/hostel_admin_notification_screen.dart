import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import 'hostel_admin_layout.dart';

class HostelAdminNotificationScreen extends StatelessWidget {
  const HostelAdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Notifications",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notices")
            .where("target", whereIn: ["all", "hostel"])
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final n = docs[index].data() as Map<String, dynamic>;
              final date = (n['createdAt'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(_iconByType(n['type']), color: appBrown),
                  title: Text(
                    n['title'] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n['description'] ?? ""),
                      const SizedBox(height: 6),
                      Text(
                        "${date.day}-${date.month}-${date.year}",
                        style: const TextStyle(fontSize: 12),
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

  IconData _iconByType(String? type) {
    switch (type) {
      case "notice":
        return Icons.campaign;
      case "leave":
        return Icons.assignment;
      case "breakage":
        return Icons.warning;
      case "mess":
        return Icons.restaurant;
      default:
        return Icons.notifications;
    }
  }
}
