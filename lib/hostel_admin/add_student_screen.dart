// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'hostel_admin_layout.dart';
import 'list_students_screen.dart';

class AddStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  final String? docId;

  const AddStudentScreen({super.key, this.studentData, this.docId});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final regCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final parentCtrl = TextEditingController();
  final deptCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String course = "UG";
  DateTime? dob;
  DateTime? joinDate;

  String? base64Image;
  bool loading = false;

  // ================= INIT (FOR UPDATE) =================
  @override
  void initState() {
    super.initState();

    if (widget.studentData != null) {
      final d = widget.studentData!;
      nameCtrl.text = d["name"] ?? "";
      regCtrl.text = d["regno"] ?? "";
      emailCtrl.text = d["email"] ?? "";
      mobileCtrl.text = d["mobile"] ?? "";
      parentCtrl.text = d["parentMobile"] ?? "";
      deptCtrl.text = d["department"] ?? "";
      yearCtrl.text = d["year"] ?? "";
      durationCtrl.text = d["duration"] ?? "";
      addressCtrl.text = d["address"] ?? "";
      course = d["course"] ?? "UG";
      dob = d["dob"] != null ? (d["dob"] as Timestamp).toDate() : null;
      joinDate = d["joiningDate"] != null
          ? (d["joiningDate"] as Timestamp).toDate()
          : null;
      base64Image = d["profileImageBase64"];
    }
  }

  // ================= IMAGE PICK =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (img == null) return;

    final bytes = await img.readAsBytes();
    setState(() => base64Image = base64Encode(bytes));
  }

  // ================= ADD / UPDATE =================
  Future<void> saveStudent() async {
    if (!_formKey.currentState!.validate() || dob == null) return;

    setState(() => loading = true);

    // ONLY CREATE AUTH USER WHEN ADDING
    if (widget.docId == null) {
      final password =
          "${dob!.day.toString().padLeft(2, '0')}"
          "${dob!.month.toString().padLeft(2, '0')}"
          "${dob!.year}";

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: password,
      );
    }

    await FirebaseFirestore.instance
        .collection("student")
        .doc(widget.docId ?? regCtrl.text.trim())
        .set({
          "name": nameCtrl.text.trim(),
          "regno": regCtrl.text.trim(),
          "email": emailCtrl.text.trim(),
          "mobile": mobileCtrl.text.trim(),
          "parentMobile": parentCtrl.text.trim(),
          "course": course,
          "dob": dob,
          "department": deptCtrl.text.trim(),
          "year": yearCtrl.text.trim(),
          "joiningDate": joinDate,
          "duration": durationCtrl.text.trim(),
          "address": addressCtrl.text.trim(),
          "profileImageBase64": base64Image,
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));

    setState(() => loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ListStudentsScreen()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: widget.docId == null ? "Add Student" : "Update Student",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: base64Image != null
                            ? MemoryImage(base64Decode(base64Image!))
                            : null,
                        child: base64Image == null
                            ? const Icon(Icons.camera_alt)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _field("Name", nameCtrl),
                  _field("Register No", regCtrl),
                  _field("Email", emailCtrl),
                  _field("Mobile", mobileCtrl),
                  _field("Parent Mobile", parentCtrl),

                  DropdownButtonFormField(
                    value: course,
                    decoration: const InputDecoration(
                      labelText: "Course",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "UG", child: Text("UG")),
                      DropdownMenuItem(value: "PG", child: Text("PG")),
                      DropdownMenuItem(
                        value: "Diploma",
                        child: Text("Diploma"),
                      ),
                    ],
                    onChanged: (v) => setState(() => course = v!),
                  ),

                  const SizedBox(height: 16),
                  _dateTile(
                    "Date of Birth",
                    dob,
                    (d) => setState(() => dob = d),
                  ),
                  const SizedBox(height: 16),

                  _field("Department", deptCtrl),
                  _field("Year", yearCtrl),

                  const SizedBox(height: 16),
                  _dateTile(
                    "Joining Date",
                    joinDate,
                    (d) => setState(() => joinDate = d),
                  ),

                  const SizedBox(height: 16),
                  _field("Duration (2021-2024)", durationCtrl),
                  _field("Address", addressCtrl, lines: 3),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : saveStudent,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.docId == null
                                  ? "ADD STUDENT"
                                  : "UPDATE STUDENT",
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _field(String label, TextEditingController c, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? value, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(1990),
          lastDate: DateTime.now(),
          initialDate: value ?? DateTime.now(),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value == null
              ? "Select $label"
              : "${value.day.toString().padLeft(2, '0')}-"
                    "${value.month.toString().padLeft(2, '0')}-"
                    "${value.year}",
        ),
      ),
    );
  }
}
