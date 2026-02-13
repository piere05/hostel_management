// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_complaint_list_screen.dart';
import 'student_layout.dart';

class RegisterComplaintScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const RegisterComplaintScreen({super.key, this.docId, this.data});

  @override
  State<RegisterComplaintScreen> createState() =>
      _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends State<RegisterComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController complaintController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 158, 53, 0);

  @override
  void initState() {
    super.initState();

    // PREFILL IF EDIT
    if (widget.data != null) {
      nameController.text = widget.data!['name'] ?? "";
      departmentController.text = widget.data!['department'] ?? "";
      yearController.text = widget.data!['year'] ?? "";
      mobileController.text = widget.data!['mobile'] ?? "";
      roomController.text = widget.data!['roomNo'] ?? "";
      complaintController.text = widget.data!['description'] ?? "";
    }
  }

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser!;

    final payload = {
      'name': nameController.text.trim(),
      'department': departmentController.text.trim(),
      'year': yearController.text.trim(),
      'mobile': mobileController.text.trim(),
      'roomNo': roomController.text.trim(),
      'description': complaintController.text.trim(),
      'status': 'Pending',
      'addedBy': user.email,
      'createdAt': Timestamp.now(),
    };

    if (widget.docId == null) {
      await FirebaseFirestore.instance
          .collection('student_complaints')
          .add(payload);
    } else {
      await FirebaseFirestore.instance
          .collection('student_complaints')
          .doc(widget.docId)
          .update(payload);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.docId == null
              ? "Complaint submitted successfully"
              : "Complaint updated successfully",
        ),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentComplaintListScreen()),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: widget.docId == null ? "Register Complaint" : "Update Complaint",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Complaint Form",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: nameController,
                    decoration: inputDecoration("Name", Icons.person),
                    validator: (v) => v!.isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: departmentController,
                    decoration: inputDecoration("Department", Icons.school),
                    validator: (v) =>
                        v!.isEmpty ? "Department is required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: yearController,
                    decoration: inputDecoration("Year", Icons.calendar_today),
                    validator: (v) => v!.isEmpty ? "Year is required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: inputDecoration("Mobile", Icons.phone),
                    validator: (v) {
                      if (v!.isEmpty) return "Mobile is required";
                      if (v.length < 10) return "Enter valid mobile number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: roomController,
                    decoration: inputDecoration("Room No", Icons.meeting_room),
                    validator: (v) => v!.isEmpty ? "Room No is required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: complaintController,
                    maxLines: 4,
                    decoration: inputDecoration(
                      "Complaint Description",
                      Icons.edit_note,
                    ),
                    validator: (v) =>
                        v!.isEmpty ? "Complaint description is required" : null,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: submitComplaint,
                      child: Text(
                        widget.docId == null
                            ? "SUBMIT COMPLAINT"
                            : "UPDATE COMPLAINT",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
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
}
