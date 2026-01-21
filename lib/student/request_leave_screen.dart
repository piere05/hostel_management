// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'leave_list_screen.dart';
import 'student_layout.dart';

class RequestLeaveScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const RequestLeaveScreen({super.key, this.docId, this.data});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  int totalDays = 0;

  final TextEditingController reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color primaryColor = const Color.fromARGB(255, 158, 53, 0);

  @override
  void initState() {
    super.initState();

    // ✅ PREFILL DATA FOR EDIT
    if (widget.data != null) {
      fromDate = (widget.data!['fromDate'] as Timestamp).toDate();
      toDate = (widget.data!['toDate'] as Timestamp).toDate();
      totalDays = widget.data!['totalDays'];
      reasonController.text = widget.data!['reason'];
    }
  }

  void calculateDays() {
    if (fromDate != null && toDate != null) {
      totalDays = toDate!.difference(fromDate!).inDays + 1;
      setState(() {});
    }
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (fromDate ?? DateTime.now())
          : (toDate ?? fromDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(fromDate!)) {
            toDate = null;
          }
        } else {
          toDate = picked;
        }
        calculateDays();
      });
    }
  }

  Future<void> submitLeave() async {
    if (!_formKey.currentState!.validate() ||
        fromDate == null ||
        toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select valid dates")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final studentDoc = await FirebaseFirestore.instance
        .collection('student')
        .where('email', isEqualTo: user.email)
        .get();
    String studentName = "";
    String studentRegno = "";

    if (studentDoc.docs.isNotEmpty) {
      final data = studentDoc.docs.first.data();

      studentName = (data['name'] ?? "").toString();
      studentRegno = (data['regno'] ?? "").toString();
    }
    final payload = {
      'studentName': studentName,
      'studentRegno': studentRegno,
      'studentEmail': user.email,
      'fromDate': fromDate,
      'toDate': toDate,
      'totalDays': totalDays,
      'reason': reasonController.text.trim(),
      'status': 'Pending',
      'createdAt': Timestamp.now(),
    };

    // ✅ ADD vs UPDATE
    if (widget.docId == null) {
      await FirebaseFirestore.instance
          .collection('student_leaves')
          .add(payload);
    } else {
      await FirebaseFirestore.instance
          .collection('student_leaves')
          .doc(widget.docId)
          .update(payload);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.docId == null
              ? "Leave submitted successfully"
              : "Leave updated successfully",
        ),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentLeaveListScreen()),
    );
  }

  Widget dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          date == null ? "Select date" : DateFormat('dd MMM yyyy').format(date),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: date == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: widget.docId == null ? "Request Leave" : "Update Leave",
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Leave Application",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  dateField(
                    label: "From Date",
                    date: fromDate,
                    onTap: () => pickDate(true),
                  ),

                  const SizedBox(height: 16),

                  dateField(
                    label: "To Date",
                    date: toDate,
                    onTap: () => pickDate(false),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      // ✅ WEB SAFE (same color visually)
                      color: const Color.fromRGBO(158, 53, 0, 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor),
                    ),
                    child: Center(
                      child: Text(
                        "Total Days : $totalDays",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.edit_note, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Reason is required" : null,
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
                      onPressed: submitLeave,
                      child: Text(
                        widget.docId == null ? "SUBMIT LEAVE" : "UPDATE LEAVE",
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
