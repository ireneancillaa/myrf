import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import '../../controller/feses_controller.dart';
import 'feses_score_input_page.dart';

import '../../widgets/empty_state_widget.dart';

class FesesScorePage extends StatefulWidget {
  const FesesScorePage({super.key});

  @override
  State<FesesScorePage> createState() => _FesesScorePageState();
}

class _FesesScorePageState extends State<FesesScorePage> {
  static const Color _primaryGreen = Color(0xFF22C55E);

  late final BroilerController _broilerController;
  late final FesesController _fesesController;

  @override
  void initState() {
    super.initState();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
        
    _fesesController = Get.isRegistered<FesesController>()
        ? Get.find<FesesController>()
        : Get.put(FesesController(), permanent: true);
  }

  BroilerProjectData? _currentProject() {
    final selectedName = _broilerController.selectedProjectName.value;
    if (selectedName == null || selectedName.trim().isEmpty) {
      return null;
    }

    for (final project in _broilerController.projects) {
      if (project.projectName == selectedName) {
        return project;
      }
    }
    return null;
  }

  Future<void> _openAddFesesScore() async {
    final result = await Navigator.of(context).push<FesesScoreEntry>(
      MaterialPageRoute(builder: (_) => const FesesScoreInputPage()),
    );

    if (result == null) return;
    _fesesController.addFesesScore(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFDADDE2), width: 1),
        ),
        title: const Text(
          'Feses Score',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        final project = _currentProject();
        if (project == null) {
          return const Center(child: Text('Please select a project first'));
        }

        final entries = _fesesController.entries;
        if (entries.isEmpty) {
          return const EmptyStateWidget(moduleName: 'Feses Score');
        }

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final item = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FesesScoreCard(entry: item),
              );
            },
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          height: 56,
          child: FloatingActionButton.extended(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onPressed: _openAddFesesScore,
            icon: const Icon(Icons.add, size: 28),
            label: const Text(
              'Feses Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FesesScoreCard extends StatelessWidget {
  const _FesesScoreCard({required this.entry});

  final FesesScoreEntry entry;

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADDE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/remarks.png',
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
                      entry.penNumber,
                      style: const TextStyle(
                        color: Color(0xFF22C55E),
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
                          entry.date,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
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
              Expanded(
                child: _MetricText(
                  label: 'Age',
                  value: '20',
                  textAlign: TextAlign.left,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MetricText(
                  label: 'Feses',
                  value: _formatNumber(entry.fesesKg),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MetricText(
                  label: 'Cawan',
                  value: _formatNumber(entry.cawanKg),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MetricText(
                  label: 'Oven',
                  value: _formatNumber(entry.ovenKg),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
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
      width: 16,
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
