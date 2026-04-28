import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/broiler_project_data.dart';

class PdfGeneratorService {
  static const _greenHeaderColor = PdfColor.fromInt(0xFF22C55E);

  static Future<Uint8List> generateProjectSummary(
    PdfPageFormat format, {
    required BroilerProjectData project,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
    required List<List<bool>> sampleGroupBluetoothFlags,
    required List<Map<String, dynamic>> docDistributions,
    required List<String> attachmentUrls,
    required Map<String, String> boxValues,
    required Map<int, List<int>> dietPens,
    required Map<int, Map<String, String>> dietInputs,
  }) async {
    final pdf = pw.Document();

    // Try to load regular and bold fonts for better rendering, fallback to default
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    // Load attachments if they are base64 strings
    final List<pw.MemoryImage> attachmentImages = [];
    for (final b64 in attachmentUrls) {
      if (b64.isNotEmpty) {
        try {
          // Typically base64 starts with data:image/jpeg;base64,
          final cleanB64 = b64.contains(',') ? b64.split(',').last : b64;
          final bytes = base64Decode(cleanB64);
          attachmentImages.add(pw.MemoryImage(bytes));
        } catch (e) {
          // Ignore invalid images
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(
          marginTop: 32,
          marginBottom: 32,
          marginLeft: 32,
          marginRight: 32,
        ),
        theme: theme,
        build: (context) {
          return [
            _buildHeader(project),
            _buildSectionTitle('1. Project Information'),
            _buildProjectInformation(project),
            pw.SizedBox(height: 20),
            _buildSectionTitle('2. Diet Configuration'),
            _buildDietConfiguration(dietInputs),
            pw.SizedBox(height: 10),
            _buildSubtitle('Pen Mapping'),
            _buildPenMapping(dietPens, dietInputs),
            pw.SizedBox(height: 20),
            _buildSectionTitle('3. Attachment'),
            _buildAttachments(attachmentImages),
            pw.SizedBox(height: 20),
            _buildSectionTitle('4. Sample DOC'),
            _buildSampleDoc(boxValues),
            pw.SizedBox(height: 20),
            _buildSubtitle('Sample Weighing & Distribution'),
            _buildSampleWeighing(sampleGroups, docDistributions, project),
            pw.SizedBox(height: 20),
            _buildSubtitle('Additional Notes'),
            _buildAdditionalNotes(),
            pw.SizedBox(height: 20),
            _buildSubtitle('Approval'),
            _buildApproval(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(BroilerProjectData project) {
    final year = DateTime.now().year;
    final idPart = project.projectId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final suffix = idPart.length >= 4 ? idPart.substring(idPart.length - 4) : idPart.padLeft(4, '0');
    final docNumber = 'PPS-$year-$suffix';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PROJECT PLANNING SUMMARY',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Summary of project trial, diet configuration, attachments, and sample DOC.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Document No.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                docNumber,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text('Prepared Date: ', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(project.trialDate, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildSubtitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.TableRow _buildInfoRow(String label1, String value1, String label2, String value2) {
    return pw.TableRow(
      children: [
        _buildCell(label1, isHeader: false, isLabel: true),
        _buildCell(value1, isHeader: false),
        _buildCell(label2, isHeader: false, isLabel: true),
        _buildCell(value2, isHeader: false),
      ],
    );
  }

  static pw.Widget _buildProjectInformation(BroilerProjectData project) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        _buildInfoRow('Project Name / Chick Cycle', project.projectName, 'Strain', project.strain),
        _buildInfoRow('Hatchery', project.hatchery, 'Breeding Farm', project.breedingFarm),
        _buildInfoRow('Box Code', project.boxBatchCode, 'Selector', project.selector),
        _buildInfoRow('Date Trial', project.trialDate, 'Weighing 3 Weeks (Kg)', project.weighing3Weeks),
        _buildInfoRow('Weighing 5 Weeks (Kg)', project.weighing5Weeks, 'Number of Birds', project.numberOfBirds),
        _buildInfoRow('DOC Weight (Kg)', project.docWeight, 'DOC In', project.docInDate),
        _buildInfoRow('Map of Trial House', project.trialHouse, 'Diet', project.diet),
        _buildInfoRow('Replication', project.replication, '', ''),
      ],
    );
  }

  static pw.Widget _buildDietConfiguration(Map<int, Map<String, String>> dietInputs) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _greenHeaderColor),
        children: [
          _buildCell('Diet', isHeader: true),
          _buildCell('Pre Starter', isHeader: true),
          _buildCell('Starter', isHeader: true),
          _buildCell('Finisher', isHeader: true),
          _buildCell('Remarks', isHeader: true),
        ],
      )
    ];

    final keys = dietInputs.keys.toList()..sort();
    if (keys.isEmpty) {
      rows.add(
        pw.TableRow(
          children: [
            _buildCell('Diet 1', isHeader: false),
            _buildCell('', isHeader: false),
            _buildCell('', isHeader: false),
            _buildCell('', isHeader: false),
            _buildCell('', isHeader: false),
          ],
        ),
      );
    } else {
      for (final dietNum in keys) {
        final input = dietInputs[dietNum] ?? {};
        rows.add(
          pw.TableRow(
            children: [
              _buildCell('Diet $dietNum', isHeader: false),
              _buildCell(input['preStarter'] ?? '', isHeader: false),
              _buildCell(input['starter'] ?? '', isHeader: false),
              _buildCell(input['finisher'] ?? '', isHeader: false),
              _buildCell(input['remarks'] ?? '', isHeader: false),
            ],
          ),
        );
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: rows,
    );
  }

  static pw.Widget _buildPenMapping(Map<int, List<int>> dietPens, Map<int, Map<String, String>> dietInputs) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _greenHeaderColor),
        children: [
          _buildCell('Pen', isHeader: true),
          _buildCell('Diet Assigned', isHeader: true),
          _buildCell('Notes', isHeader: true),
          _buildCell('Pen', isHeader: true),
          _buildCell('Diet Assigned', isHeader: true),
          _buildCell('Notes', isHeader: true),
        ],
      )
    ];

    // Determine the max number of pens
    int maxPen = 0;
    final penToDietMap = <int, int>{};
    for (final entry in dietPens.entries) {
      for (final pen in entry.value) {
        penToDietMap[pen] = entry.key;
        if (pen > maxPen) maxPen = pen;
      }
    }

    if (maxPen < 12) maxPen = 12;

    for (int i = 1; i <= maxPen; i += 2) {
      final pen1 = i;
      final pen2 = i + 1;

      final diet1 = penToDietMap[pen1];
      final diet2 = penToDietMap[pen2];

      rows.add(
        pw.TableRow(
          children: [
            _buildCell('Pen $pen1', isHeader: false, isLabel: true),
            _buildCell(diet1 != null ? 'Diet $diet1' : '', isHeader: false),
            _buildCell('', isHeader: false),
            _buildCell('Pen $pen2', isHeader: false, isLabel: true),
            _buildCell(diet2 != null ? 'Diet $diet2' : '', isHeader: false),
            _buildCell('', isHeader: false),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: rows,
    );
  }

  static pw.Widget _buildAttachments(List<pw.MemoryImage> images) {
    if (images.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Text('No attachments available.', style: const pw.TextStyle(color: PdfColors.grey600)),
      );
    }

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: images.map((img) {
        return pw.Container(
          width: 240, // Adjust width to fit 2 images in one row approximately
          height: 240,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Image(img, fit: pw.BoxFit.contain),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildSampleDoc(Map<String, String> boxValues) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _greenHeaderColor),
          children: [
            _buildCell('Category', isHeader: true),
            _buildCell('Bird ID / Sample Ref', isHeader: true),
            _buildCell('Weight (Kg)', isHeader: true),
            _buildCell('Notes', isHeader: true),
          ],
        ),
        _buildSampleDocRow('Heaviest', '', boxValues['heaviest'] ?? ''),
        _buildSampleDocRow('Average', '', boxValues['average'] ?? ''),
        _buildSampleDocRow('Lightest', '', boxValues['lightest'] ?? ''),
      ],
    );
  }

  static pw.TableRow _buildSampleDocRow(String category, String id, String weight) {
    return pw.TableRow(
      children: [
        _buildCell(category, isHeader: false, isLabel: true),
        _buildCell(id, isHeader: false),
        _buildCell(weight, isHeader: false),
        _buildCell('', isHeader: false),
      ],
    );
  }

  static pw.Widget _buildSampleWeighing(List<List<double>> sampleGroups, List<Map<String, dynamic>> docDistributions, BroilerProjectData project) {
    double totalGroup1 = 0;
    double totalGroup2 = 0;
    double totalGroup3 = 0;

    if (sampleGroups.isNotEmpty && sampleGroups[0].isNotEmpty) {
      totalGroup1 = sampleGroups[0].reduce((a, b) => a + b);
    }
    if (sampleGroups.length > 1 && sampleGroups[1].isNotEmpty) {
      totalGroup2 = sampleGroups[1].reduce((a, b) => a + b);
    }
    if (sampleGroups.length > 2 && sampleGroups[2].isNotEmpty) {
      totalGroup3 = sampleGroups[2].reduce((a, b) => a + b);
    }

    double docDistTotal = 0;
    for (final item in docDistributions) {
      final valueRaw = item['valueKg'] ?? item['value'] ?? item['kg'];
      final value = valueRaw is num ? valueRaw.toDouble() : double.tryParse('$valueRaw') ?? 0;
      docDistTotal += value;
    }

    String docDistTime = '__:__';
    if (docDistributions.isNotEmpty && docDistributions.first['updatedAt'] != null) {
      try {
        final dt = DateTime.parse(docDistributions.first['updatedAt'].toString()).toLocal();
        docDistTime = DateFormat('HH:mm').format(dt);
      } catch (_) {}
    }

    String sampleTime = project.updatedAt != null ? DateFormat('HH:mm').format(project.updatedAt!.toLocal()) : '__:__';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _greenHeaderColor),
          children: [
            _buildCell('Sample / Activity', isHeader: true),
            _buildCell('Weighing Time', isHeader: true),
            _buildCell('Total Weight (Kg)', isHeader: true),
            _buildCell('PIC / Notes', isHeader: true),
          ],
        ),
        _buildWeighingRow('Sample 1', totalGroup1 > 0 ? sampleTime : '__:__', totalGroup1 > 0 ? totalGroup1.toStringAsFixed(2) : '-'),
        _buildWeighingRow('Sample 2', totalGroup2 > 0 ? sampleTime : '__:__', totalGroup2 > 0 ? totalGroup2.toStringAsFixed(2) : '-'),
        _buildWeighingRow('Sample 3', totalGroup3 > 0 ? sampleTime : '__:__', totalGroup3 > 0 ? totalGroup3.toStringAsFixed(2) : '-'),
        _buildWeighingRow('DOC Distribution', docDistTotal > 0 ? docDistTime : '__:__', docDistTotal > 0 ? docDistTotal.toStringAsFixed(2) : '0.00'),
      ],
    );
  }

  static pw.TableRow _buildWeighingRow(String sample, String time, String weight) {
    return pw.TableRow(
      children: [
        _buildCell(sample, isHeader: false, isLabel: true),
        _buildCell(time, isHeader: false),
        _buildCell(weight, isHeader: false),
        _buildCell('', isHeader: false),
      ],
    );
  }

  static pw.Widget _buildAdditionalNotes() {
    return pw.Container(
      height: 100,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
    );
  }

  static pw.Widget _buildApproval() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          children: [
            _buildApprovalBox('Prepared By'),
            _buildApprovalBox('Reviewed By'),
            _buildApprovalBox('Approved By'),
          ],
        )
      ],
    );
  }

  static pw.Widget _buildApprovalBox(String role) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      height: 80,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(role, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Container(
            width: 120,
            height: 1,
            color: PdfColors.grey500,
          )
        ],
      ),
    );
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false, bool isLabel = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: isHeader ? PdfColors.white : PdfColors.black,
          fontSize: 9,
          fontWeight: isHeader || isLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
