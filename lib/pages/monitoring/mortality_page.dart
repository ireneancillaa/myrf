import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import '../../controller/mortality_controller.dart';
import 'mortality_input_page.dart';

class DepletionPage extends StatefulWidget {
  const DepletionPage({super.key});

  @override
  State<DepletionPage> createState() => _DepletionPageState();
}

class _DepletionPageState extends State<DepletionPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);

  late final BroilerController _broilerController;
  late final MortalityController _mortalityController;

  @override
  void initState() {
    super.initState();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
    
    _mortalityController = Get.isRegistered<MortalityController>()
        ? Get.find<MortalityController>()
        : Get.put(MortalityController(), permanent: true);
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

  Future<void> _openAddDepletion() async {
    final result = await Navigator.of(context).push<DepletionEntry>(
      MaterialPageRoute(builder: (_) => const MortalityInputPage()),
    );

    if (result == null) return;
    _mortalityController.addDepletion(result);
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
          'Depletion',
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

        return SafeArea(
          child: Obx(() {
            final entries = _mortalityController.entries;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final item = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DepletionCard(entry: item),
                );
              },
            );
          }),
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
            onPressed: _openAddDepletion,
            icon: const Icon(Icons.add, size: 28),
            label: const Text(
              'Depletion',
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

class _DepletionCard extends StatelessWidget {
  String _formatDateTime(String value) {
    // Parsing dari string, fallback ke value asli jika gagal
    DateTime? dt;
    try {
      dt = DateTime.parse(value);
    } catch (_) {
      return value;
    }
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day ${monthNames[dt.month - 1]} ${dt.year} - $hour:$minute:$second';
  }

  const _DepletionCard({required this.entry});

  final DepletionEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    'assets/chicken.png',
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
                      entry.type == 'Cull' ? 'Culling' : entry.type,
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
                          _formatDateTime(entry.date),
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
                flex: 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _MetricText(
                    label: 'Age',
                    value: entry.age,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                flex: 18,
                child: _MetricText(label: 'Pen', value: entry.penNumber),
              ),
              const _MetricDivider(),
              Expanded(
                flex: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: _MetricText(
                    label: 'Body Weight (g)',
                    value: entry.bodyWeight,
                    textAlign: TextAlign.right,
                  ),
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
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
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
