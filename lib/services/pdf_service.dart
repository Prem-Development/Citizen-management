import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../models/citizen.dart';
import '../models/custom_column.dart';
import '../models/gs_profile.dart';
import '../utils/app_constants.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _fileFormat = DateFormat('yyyyMMdd_HHmmss');

  Future<Directory> get _pdfDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, AppConstants.pdfDir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ─────────────────────────────────────────────
  // SINGLE CITIZEN PDF
  // ─────────────────────────────────────────────
  Future<File?> generateCitizenPdf(
    Citizen citizen,
    List<CustomColumn> columns,
    GSProfile profile,
  ) async {
    try {
      final doc = pw.Document();
      final photo = citizen.photo != null ? File(citizen.photo!) : null;
      pw.MemoryImage? photoImage;
      if (photo != null && photo.existsSync()) {
        photoImage = pw.MemoryImage(await photo.readAsBytes());
      }

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(profile, 'Citizen Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildCitizenContent(citizen, columns, photoImage),
        ],
      ));

      return await _savePdf(doc, 'citizen_${citizen.nic}');
    } catch (e) {
      debugPrint('PdfService single error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // FULL DATABASE PDF
  // ─────────────────────────────────────────────
  Future<File?> generateFullDatabasePdf(
    List<Citizen> citizens,
    List<CustomColumn> columns,
    GSProfile profile,
  ) async {
    try {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(profile, 'Full Database Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Text('Total Citizens: ${citizens.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 16),
          ...citizens.asMap().entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    color: PdfColors.teal50,
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${entry.key + 1}. ${entry.value.name} (${entry.value.nic})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                  _buildCitizenTable(entry.value, columns),
                  pw.SizedBox(height: 12),
                ],
              )),
        ],
      ));
      return await _savePdf(doc, 'full_database');
    } catch (e) {
      debugPrint('PdfService full db error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // FILTERED PDF
  // ─────────────────────────────────────────────
  Future<File?> generateFilteredPdf(
    List<Citizen> citizens,
    List<CustomColumn> columns,
    GSProfile profile,
    String filterDescription,
  ) async {
    try {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(profile, 'Filtered Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          if (filterDescription.isNotEmpty)
            pw.Container(
              color: PdfColors.amber50,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text('Filters: $filterDescription',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.brown)),
            ),
          pw.Text('Results: ${citizens.length} citizen(s)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 16),
          ...citizens.asMap().entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    color: PdfColors.teal50,
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${entry.key + 1}. ${entry.value.name} (${entry.value.nic})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                  _buildCitizenTable(entry.value, columns),
                  pw.SizedBox(height: 12),
                ],
              )),
        ],
      ));
      return await _savePdf(doc, 'filtered_report');
    } catch (e) {
      debugPrint('PdfService filtered error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // SHARE / PRINT
  // ─────────────────────────────────────────────
  Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: path.basename(pdfFile.path),
    );
  }

  Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) => pdfFile.readAsBytes(),
    );
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────
  pw.Widget _buildHeader(GSProfile profile, String reportTitle) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Grama Sevaka Division',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.teal)),
              if (profile.name.isNotEmpty)
                pw.Text(profile.name, style: const pw.TextStyle(fontSize: 11)),
              if (profile.division.isNotEmpty)
                pw.Text(profile.division,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(reportTitle,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text('Generated: ${_dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GS Citizen Manager', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ],
      ),
    );
  }

  pw.Widget _buildCitizenContent(
      Citizen citizen, List<CustomColumn> columns, pw.MemoryImage? photo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (photo != null) ...[
          pw.Container(
            width: 100,
            height: 120,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Image(photo, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(width: 16),
        ],
        pw.Expanded(child: _buildCitizenTable(citizen, columns)),
      ],
    );
  }

  pw.Widget _buildCitizenTable(Citizen citizen, List<CustomColumn> columns) {
    final rows = <pw.TableRow>[
      _tableRow('NIC', citizen.nic),
      _tableRow('Name', citizen.name),
      if (citizen.address.isNotEmpty) _tableRow('Address', citizen.address),
      if (citizen.village.isNotEmpty) _tableRow('Village', citizen.village),
      if (citizen.phone.isNotEmpty) _tableRow('Phone', citizen.phone),
      if (citizen.gender.isNotEmpty) _tableRow('Gender', citizen.gender),
      if (citizen.dob.isNotEmpty) _tableRow('Date of Birth', citizen.dob),
      if (citizen.family.isNotEmpty) _tableRow('Family', citizen.family),
      if (citizen.notes.isNotEmpty) _tableRow('Notes', citizen.notes),
      for (final col in columns)
        if (citizen.customValues.containsKey(col.id) &&
            (citizen.customValues[col.id] ?? '').isNotEmpty)
          _tableRow(col.columnName, citizen.customValues[col.id] ?? ''),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(110),
        1: const pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.TableRow _tableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Container(
        color: PdfColors.grey100,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ),
    ]);
  }

  Future<File> _savePdf(pw.Document doc, String baseName) async {
    final dir = await _pdfDir;
    final timestamp = _fileFormat.format(DateTime.now());
    final filePath = path.join(dir.path, '${baseName}_$timestamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
