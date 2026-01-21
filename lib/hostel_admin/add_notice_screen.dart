// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hostel_admin_layout.dart';
import 'notice_list_screen.dart';

class AddNoticeScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AddNoticeScreen({super.key, this.docId, this.data});

  @override
  State<AddNoticeScreen> createState() => _AddNoticeScreenState();
}

class _AddNoticeScreenState extends State<AddNoticeScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String? imageBase64;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      titleCtrl.text = widget.data!['title'];
      descCtrl.text = widget.data!['description'];
      imageBase64 = widget.data!['imageBase64'];
    }
  }

  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => imageBase64 = base64Encode(bytes));
  }

  Future<void> saveNotice() async {
    final data = {
      "title": titleCtrl.text.trim(),
      "description": descCtrl.text.trim(),
      "imageBase64": imageBase64 ?? "",
      "createdBy": "Admin",
      "createdAt": Timestamp.now(),

      // 🔔 IMPORTANT FOR NOTIFICATION
      "type": "notice",
      "target": "all", // all users
      "sendPush": true, // cloud function trigger
    };

    final ref = FirebaseFirestore.instance.collection("notices");

    if (widget.docId == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.docId).update(data);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NoticeListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Add Notice",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(),
                  image: imageBase64 != null && imageBase64!.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(imageBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageBase64 == null || imageBase64!.isEmpty
                    ? const Center(child: Text("Tap to add image"))
                    : null,
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveNotice,
              child: const Text("SAVE NOTICE"),
            ),
          ],
        ),
      ),
    );
  }
}
