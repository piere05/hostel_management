// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'hostel_admin_layout.dart';
import 'fees_list_screen.dart';

class AddFeeScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AddFeeScreen({super.key, this.docId, this.data});

  @override
  State<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends State<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  DateTime? deadline;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      titleCtrl.text = widget.data!['title'];
      amountCtrl.text = widget.data!['amount'].toString();
      deadline = (widget.data!['deadline'] as Timestamp).toDate();
    }
  }

  Future<void> _saveFee() async {
    final payload = {
      'title': titleCtrl.text.trim(),
      'amount': double.parse(amountCtrl.text),
      'deadline': Timestamp.fromDate(deadline!),
      'createdAt': Timestamp.now(),
      'createdBy': 'Admin',
      'target': 'students',
    };

    if (widget.docId == null) {
      await FirebaseFirestore.instance.collection('fees').add(payload);
    } else {
      await FirebaseFirestore.instance
          .collection('fees')
          .doc(widget.docId)
          .update(payload);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FeesListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: widget.docId == null ? "Add Fees" : "Edit Fees",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Fee Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    deadline == null
                        ? "Select Deadline"
                        : DateFormat('dd-MM-yyyy').format(deadline!),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => deadline = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && deadline != null) {
                    _saveFee();
                  }
                },
                child: const Text("Save Fee"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
