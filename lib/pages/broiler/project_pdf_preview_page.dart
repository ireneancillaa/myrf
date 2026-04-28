import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../models/broiler_project_data.dart';
import '../../services/pdf_generator_service.dart';

class PdfPreviewPage extends StatelessWidget {
  final BroilerProjectData project;
  final List<double> sampleWeights;
  final List<List<double>> sampleGroups;
  final List<List<bool>> sampleGroupBluetoothFlags;
  final List<Map<String, dynamic>> docDistributions;
  final List<String> attachmentUrls;
  final Map<String, String> boxValues;
  final Map<int, List<int>> dietPens;
  final Map<int, Map<String, String>> dietInputs;

  const PdfPreviewPage({
    super.key,
    required this.project,
    required this.sampleWeights,
    required this.sampleGroups,
    required this.sampleGroupBluetoothFlags,
    required this.docDistributions,
    required this.attachmentUrls,
    required this.boxValues,
    required this.dietPens,
    required this.dietInputs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDF Preview: ${project.projectName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing PDF for sharing...')),
              );
              try {
                final bytes = await PdfGeneratorService.generateProjectSummary(
                  PdfPageFormat.a4,
                  project: project,
                  sampleWeights: sampleWeights,
                  sampleGroups: sampleGroups,
                  sampleGroupBluetoothFlags: sampleGroupBluetoothFlags,
                  docDistributions: docDistributions,
                  attachmentUrls: attachmentUrls,
                  boxValues: boxValues,
                  dietPens: dietPens,
                  dietInputs: dietInputs,
                );
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'Project_Summary_${project.projectName}.pdf',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to share PDF: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfGeneratorService.generateProjectSummary(
          format,
          project: project,
          sampleWeights: sampleWeights,
          sampleGroups: sampleGroups,
          sampleGroupBluetoothFlags: sampleGroupBluetoothFlags,
          docDistributions: docDistributions,
          attachmentUrls: attachmentUrls,
          boxValues: boxValues,
          dietPens: dietPens,
          dietInputs: dietInputs,
        ),
        useActions: false, // Hides the built-in toolbar
      ),
    );
  }
}
