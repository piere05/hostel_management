import 'package:flutter/material.dart';
import 'hostel_admin_layout.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Leaves",
      child: const Center(child: Text("Leave List Page")),
    );
  }
}
