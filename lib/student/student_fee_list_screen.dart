// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../utils/fee_receipt_pdf.dart';
import 'student_layout.dart';

class StudentFeeListScreen extends StatefulWidget {
  const StudentFeeListScreen({super.key});

  @override
  State<StudentFeeListScreen> createState() => _StudentFeeListScreenState();
}

class _StudentFeeListScreenState extends State<StudentFeeListScreen> {
  late Razorpay _razorpay;

  String? _studentId;
  String? _studentName;
  String? _email;
  String? _regno;
  String? _mobile;
  String? _department;

  String? _currentFeeId;
  int _currentAmount = 0;
  String _currentTitle = "";

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---------------- RAZORPAY ----------------

  void _openRazorpay() {
    var options = {
      'key': 'rzp_test_S6S0e6VGPJ5FMo',
      'amount': _currentAmount * 100,
      'currency': 'INR',
      'name': 'Hostel Fees',
      'description': _currentTitle,
      'prefill': {'email': _email},
    };

    _razorpay.open(options);
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    await FirebaseFirestore.instance.collection('fee_payments').add({
      'feeId': _currentFeeId,
      'studentId': _studentId,
      'email': _email,
      'name': _studentName,
      'paid': true,
      'paidAt': FieldValue.serverTimestamp(),
      'paymentId': response.paymentId,
      'method': 'razorpay',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fee Payment Successful"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Failed"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return StudentLayout(
      title: "My Fees",
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('student')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get(),
        builder: (context, studentSnap) {
          if (!studentSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentSnap.data!.docs.isEmpty) {
            return const Center(child: Text("Student record not found"));
          }

          final studentDoc = studentSnap.data!.docs.first;
          final student = studentDoc.data() as Map<String, dynamic>;

          // ✅ STORE STUDENT DATA IN STATE (VERY IMPORTANT)
          _studentId = studentDoc.id;
          _studentName = student['name'];
          _email = student['email'];
          _regno = student['regno'];
          _mobile = student['mobile'];
          _department = student['department'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fees')
                .orderBy('deadline')
                .snapshots(),
            builder: (context, feeSnap) {
              if (!feeSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (feeSnap.data!.docs.isEmpty) {
                return const Center(child: Text("No fees available"));
              }

              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Title")),
                      DataColumn(label: Text("Amount")),
                      DataColumn(label: Text("Deadline")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: feeSnap.data!.docs.map((feeDoc) {
                      final fee = feeDoc.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(Text(fee['title'])),
                          DataCell(Text("₹${fee['amount']}")),
                          DataCell(
                            Text(
                              DateFormat(
                                'dd-MM-yyyy',
                              ).format(fee['deadline'].toDate()),
                            ),
                          ),
                          DataCell(_statusCell(feeDoc.id)),
                          DataCell(
                            _actionCell(
                              feeId: feeDoc.id,
                              title: fee['title'],
                              amount: fee['amount'],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _statusCell(String feeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fee_payments')
          .where('studentId', isEqualTo: _studentId)
          .where('feeId', isEqualTo: feeId)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text("Not Paid", style: TextStyle(color: Colors.red));
        }
        return const Text(
          "Paid",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _actionCell({
    required String feeId,
    required String title,
    required int amount,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fee_payments')
          .where('studentId', isEqualTo: _studentId)
          .where('feeId', isEqualTo: feeId)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return ElevatedButton(
            onPressed: () {
              _currentFeeId = feeId;
              _currentTitle = title;
              _currentAmount = amount;
              _openRazorpay();
            },
            child: const Text("Pay Now"),
          );
        }

        // ✅ PDF GENERATION (WORKING)
        return IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
          onPressed: () async {
            final payment =
                snap.data!.docs.first.data() as Map<String, dynamic>;

            await generateFeeReceiptPdf(
              student: {
                'name': _studentName!,
                'regno': _regno!,
                'mobile': _mobile!,
                'department': _department!,
              },
              fee: {'title': title, 'amount': amount},
              payment: payment,
            );
          },
        );
      },
    );
  }
}
