// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'hostel_admin_layout.dart';

class FeeStudentsStatusScreen extends StatelessWidget {
  final String feeId;
  const FeeStudentsStatusScreen({super.key, required this.feeId});

  Future<double> _getFeeAmount() async {
    final doc = await FirebaseFirestore.instance
        .collection('fees')
        .doc(feeId)
        .get();
    return (doc.data()?['amount'] ?? 0).toDouble();
  }

  Future<void> _downloadPdf(
    List<Map<String, dynamic>> rows,
    double amount,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Fee Payment Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Student Name', 'Reg No', 'Amount', 'Status'],
              data: rows
                  .map(
                    (r) => [
                      r['name'],
                      r['regno'],
                      amount.toString(),
                      r['paid'] ? 'PAID' : 'NOT PAID',
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return HostelAdminLayout(
      title: "Fee Payment Status",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('student')
            .orderBy('name')
            .snapshots(),
        builder: (context, studentSnap) {
          if (!studentSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = studentSnap.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return FutureBuilder(
            future: Future.wait([
              FirebaseFirestore.instance
                  .collection('fee_payments')
                  .where('feeId', isEqualTo: feeId)
                  .get(),
              _getFeeAmount(),
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final paymentDocs = snap.data![0] as QuerySnapshot;
              final amount = snap.data![1] as double;

              final payments = {
                for (var d in paymentDocs.docs) d['email']: d.data(),
              };

              final tableRows = students.map((doc) {
                final s = doc.data() as Map<String, dynamic>;
                final email = s['email'];
                final paid = payments.containsKey(email);

                return {
                  'name': s['name'] ?? '',
                  'regno': s['regno'] ?? '',
                  'paid': paid,
                };
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Download PDF"),
                      onPressed: () => _downloadPdf(tableRows, amount),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Student Name")),
                          DataColumn(label: Text("Reg No")),
                          DataColumn(label: Text("Amount")),
                          DataColumn(label: Text("Status")),
                        ],
                        rows: tableRows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(r['name'])),
                              DataCell(Text(r['regno'])),
                              DataCell(Text("Rs. $amount")),
                              DataCell(
                                Text(
                                  r['paid'] ? "PAID" : "NOT PAID",
                                  style: TextStyle(
                                    color: r['paid']
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
