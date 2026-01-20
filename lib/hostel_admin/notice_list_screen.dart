import 'package:flutter/material.dart';
import 'hostel_admin_layout.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Notifications",
      child: const Center(child: Text("Notifications Page")),
    );
  }
}
