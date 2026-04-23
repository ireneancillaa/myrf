import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import '../../controller/male_birds_controller.dart';
import 'male_birds_input_page.dart';

import '../../widgets/empty_state_widget.dart';

class MaleBirdsPage extends StatefulWidget {
  const MaleBirdsPage({super.key});

  @override
  State<MaleBirdsPage> createState() => _MaleBirdsPageState();
}

class _MaleBirdsPageState extends State<MaleBirdsPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);

  late final BroilerController _broilerController;
  late final MaleBirdsController _maleBirdsController;

  @override
  void initState() {
    super.initState();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
        
    _maleBirdsController = Get.isRegistered<MaleBirdsController>()
        ? Get.find<MaleBirdsController>()
        : Get.put(MaleBirdsController(), permanent: true);
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

  Future<void> _openAddMaleBirds() async {
    final nowIso = DateTime.now().toIso8601String();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MaleBirdsInputPage(initialDate: nowIso),
      ),
    );
    if (result == null) return;
    final date = result['date'] as String? ?? nowIso;
    final values = result['values'] as List<double>? ?? [];
    final age = result['age']?.toString() ?? '-'; 
    String formatNum(double? val) {
      if (val == null) return '-';
      if (val % 1 == 0) {
        return val.toInt().toString();
      } else {
        return val.toStringAsFixed(2);
      }
    }

    final male = values.isNotEmpty ? formatNum(values[0]) : '-';
    
    int numberOfBirds = 0;
    final project = _currentProject();
    if (project != null) {
      numberOfBirds = int.tryParse(project.numberOfBirds) ?? 0;
    }
    
    int currentTotalMale = 0;
    for (final e in _maleBirdsController.entries) {
      currentTotalMale += int.tryParse(e.male) ?? 0;
    }
    final newMaleValue = int.tryParse(male) ?? 0;
    currentTotalMale += newMaleValue;
    
    _maleBirdsController.addMaleBirds(
      MaleBirdsEntry(
        date: date,
        age: age,
        male: male,
        female: (numberOfBirds - currentTotalMale).toString(),
        recordedAt: DateTime.now(),
      ),
    );
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
          'Male Birds',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_maleBirdsController.entries.isEmpty) {
            return const EmptyStateWidget(moduleName: 'Male Birds');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _maleBirdsController.entries.length,
            itemBuilder: (context, index) {
              final item = _maleBirdsController.entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MaleBirdsCard(
                  entry: item,
                ),
              );
            },
          );
        }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: SizedBox(
          height: 56,
          child: FloatingActionButton.extended(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onPressed: _openAddMaleBirds,
            icon: const Icon(Icons.add, size: 28),
            label: const Text(
              'Male Birds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaleBirdsCard extends StatelessWidget {
  const _MaleBirdsCard({required this.entry});

  String _formatDateTime(String value) {
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

  final MaleBirdsEntry entry;

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
                  child: SvgPicture.asset(
                    'assets/male.svg',
                    width: 25,
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Male Birds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    SizedBox(height: 4),
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
                            fontSize: 13,
                            color: Color(0xFF4B5563),
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
                child: _MetricText(
                  label: 'Male',
                  value: entry.male,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                flex: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: _MetricText(
                    label: 'Female',
                    value: entry.female,
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
