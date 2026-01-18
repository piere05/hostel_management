import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'hostel_admin_layout.dart';
import 'breakage_list_screen.dart';

class AddBreakageScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AddBreakageScreen({super.key, this.docId, this.data});

  @override
  State<AddBreakageScreen> createState() => _AddBreakageScreenState();
}

class _AddBreakageScreenState extends State<AddBreakageScreen> {
  final reasonCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  String? studentId;
  String studentName = "";
  String regno = "";
  String mobile = "";
  String status = "not_paid";
  String? imageBase64;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      reasonCtrl.text = widget.data!['reason'] ?? "";
      amountCtrl.text = widget.data!['amount'].toString();
      studentName = widget.data!['studentName'] ?? "";
      regno = widget.data!['regno'] ?? "";
      mobile = widget.data!['mobile'] ?? "";
      status = widget.data!['status'] ?? "not_paid";
      imageBase64 = widget.data!['imageBase64'];
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    final bytes = await img.readAsBytes();
    setState(() => imageBase64 = base64Encode(bytes));
  }

  Future<void> saveBreakage() async {
    if (studentName.isEmpty) return;

    final data = {
      "studentName": studentName,
      "regno": regno,
      "mobile": mobile,
      "reason": reasonCtrl.text,
      "amount": int.tryParse(amountCtrl.text) ?? 0,
      "status": status,
      "imageBase64": imageBase64,
      "date": Timestamp.now(),
      "createdAt": Timestamp.now(),
    };

    final ref = FirebaseFirestore.instance.collection("breakage");

    if (widget.docId == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.docId).update(data);
    }

    // ✅ ALWAYS GO TO LIST PAGE
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BreakageListScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: widget.docId == null ? "Add Breakage" : "Update Breakage",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// SELECT STUDENT
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection("student").snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox();

                return DropdownButtonFormField<String>(
                  value: studentId,
                  hint: Text(
                    studentName.isEmpty
                        ? "Select Student"
                        : "$studentName ($regno)",
                  ),
                  items: snap.data!.docs.map((d) {
                    final s = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: d.id,
                      child: Text("${s['name']} (${s['regno']})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    final s = snap.data!.docs
                        .firstWhere((e) => e.id == val)
                        .data() as Map<String, dynamic>;

                    setState(() {
                      studentId = val;
                      studentName = s['name'];
                      regno = s['regno'];
                      mobile = s['mobile'];
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  labelText: "Reason", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Amount", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: "not_paid", child: Text("Not Paid")),
                DropdownMenuItem(value: "paid", child: Text("Paid")),
              ],
              onChanged: (v) => setState(() => status = v!),
              decoration: const InputDecoration(
                  labelText: "Status", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(),
                  image: imageBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(imageBase64!)),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: imageBase64 == null
                    ? const Center(child: Text("Tap to add image"))
                    : null,
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveBreakage,
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }
}
