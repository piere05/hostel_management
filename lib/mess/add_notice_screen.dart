import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'mess_layout.dart';
import 'notice_list_screen.dart';

class AddNoticeScreen extends StatefulWidget {
  final String? editId;
  final String? editTitle;
  final String? editDesc;
  final bool? editSendPush;

  const AddNoticeScreen({
    super.key,
    this.editId,
    this.editTitle,
    this.editDesc,
    this.editSendPush,
  });

  @override
  State<AddNoticeScreen> createState() => _AddNoticeScreenState();
}

class _AddNoticeScreenState extends State<AddNoticeScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  bool sendPush = true;

  @override
  void initState() {
    super.initState();

    // ✏️ EDIT MODE (prefill)
    if (widget.editId != null) {
      titleCtrl.text = widget.editTitle ?? "";
      descCtrl.text = widget.editDesc ?? "";
      sendPush = widget.editSendPush ?? true;
    }
  }

  Future<void> _saveNotice() async {
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) return;

    final ref = FirebaseFirestore.instance.collection('notices');

    if (widget.editId == null) {
      // ➕ ADD
      await ref.add({
        'title': title,
        'description': desc,
        'type': 'notice',
        'target': 'all',
        'sendPush': sendPush,
        'imageBase64': '',
        'createdBy': 'Mess Admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // ✏️ UPDATE
      await ref.doc(widget.editId).update({
        'title': title,
        'description': desc,
        'sendPush': sendPush,
      });
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NoticeListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MessLayout(
      title: widget.editId == null ? "Add Notice" : "Edit Notice",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: sendPush,
              title: const Text("Send Push Notification"),
              onChanged: (v) => setState(() => sendPush = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNotice,
              child: const Text("SAVE NOTICE"),
            ),
          ],
        ),
      ),
    );
  }
}
