// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'mess_layout.dart';
import 'menu_list_screen.dart';

class AddMenuScreen extends StatefulWidget {
  final String? editDay;
  final String? editMenu;

  const AddMenuScreen({super.key, this.editDay, this.editMenu});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final menuCtrl = TextEditingController();
  String day = "Sunday";

  final days = const [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  @override
  void initState() {
    super.initState();

    // ✏️ EDIT MODE (prefill)
    if (widget.editDay != null) {
      day = widget.editDay!;
      menuCtrl.text = widget.editMenu ?? "";
    }
  }

  Future<void> _saveMenu() async {
    final menu = menuCtrl.text.trim();
    if (menu.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('mess_menu')
        .doc(day) // 👈 one doc per day (insert/update)
        .set({
          'day': day,
          'menu': menu,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MessLayout(
      title: widget.editDay == null ? "Add Menu" : "Edit Menu",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: day,
              items: days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => day = v!),
              decoration: const InputDecoration(labelText: "Select Day"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: menuCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Menu Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMenu,
              child: const Text("SAVE MENU"),
            ),
          ],
        ),
      ),
    );
  }
}
