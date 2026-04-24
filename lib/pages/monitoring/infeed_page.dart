import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/broiler_controller.dart';
import '../../controller/infeed_controller.dart';
import 'package:intl/intl.dart';
import '../../models/broiler_project_data.dart';
import '../../widgets/empty_state_widget.dart';
import 'infeed_input_page.dart';

class InfeedPage extends StatefulWidget {
  const InfeedPage({super.key});

  @override
  State<InfeedPage> createState() => _InfeedPageState();
}

class _InfeedPageState extends State<InfeedPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);

  late final BroilerController _controller;
  late final InfeedController _infeedController;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);

    _infeedController = Get.isRegistered<InfeedController>()
        ? Get.find<InfeedController>()
        : Get.put(InfeedController(), permanent: true);
  }

  BroilerProjectData? _currentProject() {
    final selectedName = _controller.selectedProjectName.value;
    if (selectedName == null || selectedName.trim().isEmpty) {
      return null;
    }

    for (final project in _controller.projects) {
      if (project.projectName == selectedName) {
        return project;
      }
    }
    return null;
  }
  String _calculateAge(String dateStr, BroilerProjectData? project) {
    if (project == null) return '-';
    try {
      final inputDate = DateFormat('dd/MM/yyyy').parse(dateStr);
      final docInParts = project.docInDate.split('/');
      if (docInParts.length == 3) {
        final docInDate = DateTime(
          int.parse(docInParts[2]),
          int.parse(docInParts[1]),
          int.parse(docInParts[0]),
        );
        final diff = inputDate.difference(docInDate).inDays;
        return (diff + 1).toString();
      }
    } catch (e) {
      // ignore
    }
    return '-';
  }


  String _formatTimestamp(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy - HH:mm:ss').format(date);
  }

  String _formatWeight(double weight) {
    if (weight == 0) return '-';
    final formatter = NumberFormat('#,##0.##########');
    return formatter.format(weight);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textPrimary),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'Infeed',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () {
                // TODO: Implement PDF export
              },
              icon: const Icon(Icons.picture_as_pdf, color: _textPrimary),
              tooltip: 'Export PDF',
            ),
          ),
        ],
      ),
      body: Obx(() {
        final project = _currentProject();
        if (project == null) {
          return const Center(child: Text('Please select a project first'));
        }

        // Tampilkan empty state jika belum ada data infeed
        if (_infeedController.infeedList.isEmpty) {
          return const EmptyStateWidget(moduleName: 'Infeed');
        }
        // Tampilkan list data infeed
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _infeedController.infeedList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final infeed = _infeedController.infeedList[index];
            final age = _calculateAge(infeed.dateStr, project);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8EE),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/infeed.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              infeed.stageName,
                              style: const TextStyle(
                                color: _primaryGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimestamp(infeed.updatedAt),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MetricText(
                        label: 'Age',
                        value: age,
                        textAlign: TextAlign.left,
                      ),
                      const _MetricDivider(),
                      _MetricText(
                        label: 'Infeed Weight',
                        value: _formatWeight(infeed.weight),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: () {
          _infeedController.resetData();
          Get.to(() => const InfeedInputPage());
        },
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Infeed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({
    required this.label,
    required this.value,
    this.textAlign = TextAlign.center,
  });

  final String label;
  final String value;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 50,
      child: Center(
        child: Text(
          '|',
          style: TextStyle(
            color: Color(0xFF7D7D7D),
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

