import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../screens/login_screen.dart';
import '../screens/mess_admin_dashboard.dart';

import '../screens/mess_menu_screen.dart';
import 'add_menu_screen.dart';
import 'menu_list_screen.dart';
import 'add_notice_screen.dart';
import 'notice_list_screen.dart';
import 'mess_notification_screen.dart';

class MessLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const MessLayout({super.key, required this.child, required this.title});

  @override
  State<MessLayout> createState() => _MessLayoutState();
}

class _MessLayoutState extends State<MessLayout> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      // ================= DRAWER =================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: appBrown),
              child: Text(
                "Mess Admin",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),

            ExpansionPanelList.radio(
              children: [
                ExpansionPanelRadio(
                  value: "menu",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.restaurant_menu),
                    title: Text("Manage Mess Menu"),
                  ),
                  body: Column(
                    children: [
                      _sub("Add Menu", () => _go(const AddMenuScreen())),
                      _sub("List Menu", () => _go(const MenuListScreen())),
                    ],
                  ),
                ),
                ExpansionPanelRadio(
                  value: "notice",
                  headerBuilder: (_, __) => const ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text("Manage Notices"),
                  ),
                  body: Column(
                    children: [
                      _sub("Add Notice", () => _go(const AddNoticeScreen())),
                      _sub("List Notices", () => _go(const NoticeListScreen())),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),

      body: widget.child,

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: appBrown,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) _go(const MessDashboard());
          if (i == 1) _go(const MessNotificationScreen());
          if (i == 2) _go(const MessMenuScreen());
          if (i == 3) _logout();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: "Mess Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }

  Widget _sub(String t, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72),
      title: Text(t),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
