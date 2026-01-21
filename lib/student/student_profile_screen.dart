// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'student_layout.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final addressCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();

  String? selectedCourse; // UG / PG / Diploma
  String? profileImageBase64;

  bool loading = true;
  String? docId;

  final courseTypes = ['UG', 'PG', 'Diploma'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final email = FirebaseAuth.instance.currentUser!.email!
        .trim()
        .toLowerCase();

    final snap = await FirebaseFirestore.instance
        .collection('student')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final data = doc.data();

      docId = doc.id;

      addressCtrl.text = data['address'] ?? '';
      yearCtrl.text = data['year'] ?? '';
      departmentCtrl.text = data['department'] ?? '';
      selectedCourse = data['course'];
      profileImageBase64 = data['profileImageBase64'];
    } else {
      // 🔴 THIS means email mismatch or missing field
      debugPrint('❌ No student document found for email: $email');
    }

    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (img == null) return;

    final bytes = await img.readAsBytes();
    setState(() {
      profileImageBase64 = base64Encode(bytes);
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('student').doc(docId).update({
      'profileImageBase64': profileImageBase64 ?? '',
      'address': addressCtrl.text.trim(),
      'year': yearCtrl.text.trim(),
      'department': departmentCtrl.text.trim(),
      'course': selectedCourse, // UG / PG / Diploma
      'updatedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: "My Profile",
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _profileImage(),
                    const SizedBox(height: 20),

                    _input(
                      controller: addressCtrl,
                      label: 'Address',
                      maxLines: 2,
                    ),

                    _input(controller: yearCtrl, label: 'Year'),

                    _dropdown(
                      label: 'Course Type',
                      value: selectedCourse,
                      items: courseTypes,
                      onChanged: (v) => setState(() => selectedCourse = v),
                    ),

                    _input(controller: departmentCtrl, label: 'Department'),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Update Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _profileImage() {
    Uint8List? imgBytes =
        profileImageBase64 == null || profileImageBase64!.isEmpty
        ? null
        : base64Decode(profileImageBase64!);

    return Column(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundImage: imgBytes != null ? MemoryImage(imgBytes) : null,
          child: imgBytes == null ? const Icon(Icons.person, size: 50) : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Photo'),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
