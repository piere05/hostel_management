// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_layout.dart';

class StudentChangePasswordScreen extends StatefulWidget {
  const StudentChangePasswordScreen({super.key});

  @override
  State<StudentChangePasswordScreen> createState() =>
      _StudentChangePasswordScreenState();
}

class _StudentChangePasswordScreenState
    extends State<StudentChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final currentPwdCtrl = TextEditingController();
  final newPwdCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();

  bool loading = false;
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email!;

      // 🔐 Re-authentication
      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPwdCtrl.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      // 🔄 Update password
      await user.updatePassword(newPwdCtrl.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );

      currentPwdCtrl.clear();
      newPwdCtrl.clear();
      confirmPwdCtrl.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Password update failed')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentLayout(
      title: "Change Password",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _passwordField(
                controller: currentPwdCtrl,
                label: 'Current Password',
                hide: hideCurrent,
                toggle: () => setState(() => hideCurrent = !hideCurrent),
              ),

              _passwordField(
                controller: newPwdCtrl,
                label: 'New Password',
                hide: hideNew,
                toggle: () => setState(() => hideNew = !hideNew),
              ),

              _passwordField(
                controller: confirmPwdCtrl,
                label: 'Confirm New Password',
                hide: hideConfirm,
                toggle: () => setState(() => hideConfirm = !hideConfirm),
                confirm: true,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : _changePassword,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hide,
    required VoidCallback toggle,
    bool confirm = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: hide,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';

          if (confirm && v != newPwdCtrl.text) {
            return 'Passwords do not match';
          }

          if (!confirm && v.length < 6) {
            return 'Minimum 6 characters';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
