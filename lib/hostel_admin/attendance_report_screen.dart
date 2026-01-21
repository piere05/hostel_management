// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'hostel_admin_layout.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  int month = DateTime.now().month;
  int year = DateTime.now().year;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  final monthNames = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(daysInMonth(year, month), (i) => i + 1);

    return HostelAdminLayout(
      title: "Attendance Report",
      child: Column(
        children: [
          _filterBar(days),
          Expanded(child: _attendanceView(days)),
        ],
      ),
    );
  }

  Widget _filterBar(List<int> days) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: month,
              decoration: const InputDecoration(labelText: "Month"),
              items: List.generate(
                12,
                (i) =>
                    DropdownMenuItem(value: i + 1, child: Text(monthNames[i])),
              ),
              onChanged: (v) => setState(() => month = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: year,
              decoration: const InputDecoration(labelText: "Year"),
              items: List.generate(
                6,
                (i) => DropdownMenuItem(
                  value: 2024 + i,
                  child: Text((2024 + i).toString()),
                ),
              ),
              onChanged: (v) => setState(() => year = v!),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _downloadPdf(days, monthNames[month - 1]),
          ),
        ],
      ),
    );
  }

  Widget _attendanceView(List<int> days) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("student")
          .orderBy("name")
          .snapshots(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = studentSnap.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("attendance")
              .snapshots(),
          builder: (context, attSnap) {
            if (!attSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final Map<int, Map<String, bool>> attendanceMap = {};

            for (var doc in attSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (!data.containsKey("date") || !data.containsKey("records"))
                continue;

              final date = DateTime.parse(data["date"]);
              if (date.year != year || date.month != month) continue;

              attendanceMap.putIfAbsent(date.day, () => {});
              final records = Map<String, dynamic>.from(data["records"]);

              records.forEach((r, p) {
                attendanceMap[date.day]![r] = p == true;
              });
            }

            return SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    _headerRow(days),
                    ...students.map((s) {
                      final m = s.data() as Map<String, dynamic>;
                      final regno = m['regno'];
                      final total = days
                          .where((d) => attendanceMap[d]?[regno] == true)
                          .length;

                      return _dataRow(
                        name: m['name'] ?? "",
                        days: days,
                        isPresent: (d) => attendanceMap[d]?[regno] == true,
                        total: total,
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _headerRow(List<int> days) {
    return Row(
      children: [
        _cell("Student", 130, header: true),
        ...days.map(
          (d) => _cell(
            d.toString().padLeft(2, '0'),
            38,
            header: true,
            center: true,
          ),
        ),
        _cell("Total Present", 50, header: true, center: true),
      ],
    );
  }

  Widget _dataRow({
    required String name,
    required List<int> days,
    required bool Function(int) isPresent,
    required int total,
  }) {
    return Row(
      children: [
        _cell(name, 130),
        ...days.map((d) {
          final p = isPresent(d);
          return _cell(
            p ? "P" : "A",
            38,
            center: true,
            color: p
                ? Colors.green.shade700
                : const Color.fromARGB(255, 255, 0, 0),
          );
        }),
        _cell(total.toString(), 50, center: true, bold: true),
      ],
    );
  }

  Widget _cell(
    String text,
    double width, {
    bool header = false,
    bool center = false,
    bool bold = false,
    Color? color,
  }) {
    return Container(
      width: width,
      height: 36,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: header ? Colors.blueGrey.shade100 : null,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: header || bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black,
        ),
      ),
    );
  }

  // ================= PDF EXPORT (SAFE) =================
  Future<void> _downloadPdf(List<int> days, String monthName) async {
    final pdf = pw.Document();

    final studentsSnap = await FirebaseFirestore.instance
        .collection("student")
        .orderBy("name")
        .get();

    final attendanceSnap = await FirebaseFirestore.instance
        .collection("attendance")
        .get();

    final Map<int, Map<String, bool>> attendanceMap = {};

    for (var doc in attendanceSnap.docs) {
      final data = doc.data();
      if (!data.containsKey("date") || !data.containsKey("records")) continue;

      final date = DateTime.parse(data["date"]);
      if (date.year != year || date.month != month) continue;

      attendanceMap.putIfAbsent(date.day, () => {});
      final records = Map<String, dynamic>.from(data["records"]);

      records.forEach((regno, present) {
        attendanceMap[date.day]![regno] = present == true;
      });
    }

    const double nameColWidth = 75;
    const double dayColWidth = 18;
    const double totalColWidth = 30;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Attendance Report - $monthName $year",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(nameColWidth),
                  for (int i = 0; i < days.length; i++)
                    i + 1: const pw.FixedColumnWidth(dayColWidth),
                  days.length + 1: const pw.FixedColumnWidth(totalColWidth),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey100,
                    ),
                    children: [
                      _pdfCell("Student", bold: true),
                      ...days.map(
                        (d) => _pdfCell(d.toString(), bold: true, center: true),
                      ),
                      _pdfCell("Total", bold: true, center: true),
                    ],
                  ),
                  ...studentsSnap.docs.map((s) {
                    final m = s.data();
                    final regno = m['regno'];

                    final presentDays = days
                        .where((d) => attendanceMap[d]?[regno] == true)
                        .length;

                    return pw.TableRow(
                      children: [
                        _pdfCell(m['name'] ?? ""),
                        ...days.map((day) {
                          final present = attendanceMap[day]?[regno] == true;
                          return _pdfCell(
                            present ? "P" : "A",
                            center: true,
                            color: present ? PdfColors.green700 : PdfColors.red,
                          );
                        }),
                        _pdfCell(
                          presentDays.toString(),
                          center: true,
                          bold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    bool center = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
