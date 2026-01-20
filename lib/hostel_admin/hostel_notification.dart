import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'hostel_admin_layout.dart';

class hostel_admin_notification_screen extends StatelessWidget {
  const hostel_admin_notification_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Notifications",
      child: StreamBuilder<QuerySnapshot>(
        // 🔴 REAL-TIME LISTENER (NO REFRESH REQUIRED)
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('createdAt', descending: true)
            .limit(7) // latest 7
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState();
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final ts = data['createdAt'] as Timestamp?;
              final date = ts == null
                  ? ''
                  : DateFormat('dd-MM-yy').format(ts.toDate());

              return _notificationTile(
                title: data['title'] ?? '',
                desc: data['description'] ?? '',
                by: data['createdBy'] ?? 'Admin',
                date: date,
                imageBase64: data['imageBase64'],
                color:
                    Colors.primaries[index % Colors.primaries.length],
              );
            },
          );
        },
      ),
    );
  }

  // 🔔 BRIGHT + COMPACT + SMART TILE
  Widget _notificationTile({
    required String title,
    required String desc,
    required String by,
    required String date,
    required Color color,
    String? imageBase64,
  }) {
    final hasImage =
        imageBase64 != null && imageBase64.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼 IMAGE ONLY IF EXISTS (NO EMPTY SPACE)
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(imageBase64!),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),

          if (hasImage) const SizedBox(width: 10),

          // 📝 TEXT (EXPANDS FULL WIDTH IF NO IMAGE)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE + BY (SAME LINE)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      " By: $by",
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // DESC + DATE (SAME LINE)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_none,
              size: 70, color: Colors.grey),
          SizedBox(height: 12),
          Text("No notifications yet"),
        ],
      ),
    );
  }
}
