// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'student_layout.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  int month = DateTime.now().month;
  int year = DateTime.now().year;

  String? regNo;
  String? studentName;

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
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("student")
        .where("email", isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty && mounted) {
      setState(() {
        regNo = snap.docs.first["regno"];
        studentName = snap.docs.first["name"];
      });
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(daysInMonth(year, month), (i) => i + 1);

    return StudentLayout(
      title: "Attendance Report",
      child: regNo == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _filterBar(days),
                Expanded(child: _attendanceView(days)),
              ],
            ),
    );
  }

  // ================= FILTER BAR =================
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

  // ================= TABLE VIEW =================
  Widget _attendanceView(List<int> days) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("attendance").snapshots(),
      builder: (context, attSnap) {
        if (!attSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<int, bool> attendanceMap = {};

        for (var doc in attSnap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey("date") || !data.containsKey("records"))
            continue;

          DateTime? date;
          try {
            date = DateTime.parse(data["date"]);
          } catch (_) {
            continue;
          }

          if (date.year != year || date.month != month) continue;

          final records = Map<String, dynamic>.from(data["records"]);
          if (records[regNo] == true) {
            attendanceMap[date.day] = true;
          }
        }

        final total = days.where((d) => attendanceMap[d] == true).length;

        return SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                _headerRow(days),
                _dataRow(
                  name: studentName ?? "",
                  days: days,
                  isPresent: (d) => attendanceMap[d] == true,
                  total: total,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= TABLE ROWS =================
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
                : const Color.fromARGB(255, 255, 3, 3),
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

  // ================= PDF EXPORT =================
  Future<void> _downloadPdf(List<int> days, String monthName) async {
    final pdf = pw.Document();
    final Map<int, bool> attendanceMap = {};

    final attendanceSnap = await FirebaseFirestore.instance
        .collection("attendance")
        .get();

    for (var doc in attendanceSnap.docs) {
      final data = doc.data();
      if (!data.containsKey("date") || !data.containsKey("records")) continue;

      DateTime? date;
      try {
        date = DateTime.parse(data["date"]);
      } catch (_) {
        continue;
      }

      if (date.year != year || date.month != month) continue;

      final records = Map<String, dynamic>.from(data["records"]);
      if (records[regNo] == true) {
        attendanceMap[date.day] = true;
      }
    }

    final total = days.where((d) => attendanceMap[d] == true).length;

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
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ["Student", ...days.map((d) => d.toString()), "Total"],
                data: [
                  [
                    studentName ?? "",
                    ...days.map((d) => attendanceMap[d] == true ? "P" : "A"),
                    total.toString(),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
