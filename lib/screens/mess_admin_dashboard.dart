// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../mess/mess_layout.dart';
import '../mess/add_menu_screen.dart';
import '../mess/menu_list_screen.dart';
import '../mess/add_notice_screen.dart';
import '../mess/notice_list_screen.dart';

class MessDashboard extends StatefulWidget {
  const MessDashboard({super.key});

  @override
  State<MessDashboard> createState() => _MessDashboardState();
}

class _MessDashboardState extends State<MessDashboard> {
  @override
  Widget build(BuildContext context) {
    return MessLayout(
      title: "Mess Dashboard",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Mess Admin 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Manage daily menus and notices",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _card(
                  context,
                  title: "Add Menu",
                  icon: Icons.add_circle,
                  color: Colors.green,
                  page: const AddMenuScreen(),
                ),
                _card(
                  context,
                  title: "List Menu",
                  icon: Icons.restaurant_menu,
                  color: Colors.orange,
                  page: const MenuListScreen(),
                ),
                _card(
                  context,
                  title: "Add Notice",
                  icon: Icons.notifications_active,
                  color: Colors.blue,
                  page: const AddNoticeScreen(),
                ),
                _card(
                  context,
                  title: "List Notices",
                  icon: Icons.list_alt,
                  color: Colors.purple,
                  page: const NoticeListScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
