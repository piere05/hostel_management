import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// CALL THIS FUNCTION TO GENERATE + OPEN PDF
Future<void> generateFeeReceiptPdf({
  required Map<String, dynamic> student,
  required Map<String, dynamic> fee,
  required Map<String, dynamic> payment,
}) async {
  final pdf = pw.Document();

  final Uint8List logoBytes = (await rootBundle.load(
    'assets/images/logo.jpg',
  )).buffer.asUint8List();

  final logo = pw.MemoryImage(logoBytes);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo, width: 70),

                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Murphy Hostel",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Date: ${_formatDate(payment['paidAt'])}",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),

            // STUDENT DETAILS
            pw.Text(
              "Student Details",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            _detailRow("Name", student['name']),
            _detailRow("Reg No", student['regno']),
            _detailRow("Mobile", student['mobile']),
            _detailRow("Department", student['department']),

            pw.SizedBox(height: 20),

            // PAYMENT TABLE
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(90),
                4: const pw.FixedColumnWidth(90),
              },
              children: [
                _tableHeader(),
                _tableRow(
                  sno: "1",
                  title: fee['title'],
                  amount: "Rs. ${fee['amount']}",
                  method: payment['method'],
                  date: _formatDate(payment['paidAt']),
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Authorized Signature",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

// ---------------- HELPERS ----------------

pw.Widget _detailRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(
            "$label:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(value),
      ],
    ),
  );
}

pw.TableRow _tableHeader() {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
    children: [
      _cell("S.No", bold: true),
      _cell("Title", bold: true),
      _cell("Amount", bold: true),
      _cell("Paid With", bold: true),
      _cell("Paid On", bold: true),
    ],
  );
}

pw.TableRow _tableRow({
  required String sno,
  required String title,
  required String amount,
  required String method,
  required String date,
}) {
  return pw.TableRow(
    children: [
      _cell(sno),
      _cell(title),
      _cell(amount),
      _cell(method),
      _cell(date),
    ],
  );
}

pw.Widget _cell(String text, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

String _formatDate(dynamic timestamp) {
  final d = timestamp.toDate();
  return "${d.day.toString().padLeft(2, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.year}";
}
