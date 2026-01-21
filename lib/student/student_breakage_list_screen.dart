// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'student_layout.dart';

class StudentBreakageListScreen extends StatefulWidget {
  const StudentBreakageListScreen({super.key});

  @override
  State<StudentBreakageListScreen> createState() =>
      _StudentBreakageListScreenState();
}

class _StudentBreakageListScreenState extends State<StudentBreakageListScreen> {
  late Razorpay _razorpay;
  String? _currentDocId;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void openRazorpay(Map<String, dynamic> data, String docId) {
    _currentDocId = docId;

    var options = {
      'key': 'rzp_test_S6S0e6VGPJ5FMo', // NEW TEST KEY
      'amount': data['amount'] * 100,
      'currency': 'INR',
      'name': 'Hostel Breakage',
      'description': data['reason'],
      'prefill': {
        'contact': data['mobile'],
        'email': FirebaseAuth.instance.currentUser!.email,
      },
      'retry': {'enabled': true, 'max_count': 1},
      'timeout': 120,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentDocId == null) return;

    await FirebaseFirestore.instance
        .collection('breakage')
        .doc(_currentDocId)
        .update({
          'status': 'paid',
          'method': 'razorpay',
          'paymentId': response.paymentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Successful"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Failed"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return StudentLayout(
      title: "My Breakage Bills",
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('student')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Student record not found"));
          }

          final student =
              studentSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          final regno = student['regno'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('breakage')
                .where('regno', isEqualTo: regno)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No breakage records"));
              }

              final docs = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Reason')),
                    DataColumn(label: Text('Image')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return DataRow(
                      cells: [
                        DataCell(Text(data['reason'])),

                        DataCell(
                          Text(
                            data['imageBase64'] == null ||
                                    data['imageBase64'] == ''
                                ? '-'
                                : 'View',
                          ),
                        ),

                        DataCell(Text('₹${data['amount']}')),

                        DataCell(
                          Text(
                            DateFormat(
                              'dd-MM-yyyy',
                            ).format(data['date'].toDate()),
                          ),
                        ),

                        DataCell(
                          Text(
                            data['status'] == 'paid' ? 'Paid' : 'Not Paid',
                            style: TextStyle(
                              color: data['status'] == 'paid'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        DataCell(
                          data['status'] == 'not_paid'
                              ? ElevatedButton(
                                  onPressed: () {
                                    openRazorpay(data, doc.id);
                                  },
                                  child: const Text("Pay Now"),
                                )
                              : const Text('-'),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
