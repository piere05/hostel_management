import 'package:flutter/material.dart';
import 'hostel_admin_layout.dart';

class MessMenuScreen extends StatelessWidget {
  const MessMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Mess Menu",
      child: const Center(child: Text("Mess Menu Page")),
    );
  }
}
