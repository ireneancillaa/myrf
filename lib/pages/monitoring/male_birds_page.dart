import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import 'male_birds_input_page.dart';

class MaleBirdsPage extends StatefulWidget {
  const MaleBirdsPage({super.key});

  @override
  State<MaleBirdsPage> createState() => _MaleBirdsPageState();
}

class _MaleBirdsPageState extends State<MaleBirdsPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);

  late final BroilerController _controller;
  final List<MaleBirdsEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
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

  Future<void> _openAddMaleBirds() async {
    final nowIso = DateTime.now().toIso8601String();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MaleBirdsInputPage(initialDate: nowIso),
      ),
    );
    if (result == null) return;
    // Ambil data dari result
    final date = result['date'] as String? ?? nowIso;
    final values = result['values'] as List<double>? ?? [];
    String formatNum(double? val) {
      if (val == null) return '-';
      if (val % 1 == 0) {
        return val.toInt().toString();
      } else {
        return val.toStringAsFixed(2);
      }
    }

    final male = values.isNotEmpty ? formatNum(values[0]) : '-';
    final female = values.length > 1 ? formatNum(values[1]) : '-';
    final age = result['age']?.toString() ?? '-';
    setState(() {
      _entries.insert(
        0,
        MaleBirdsEntry(date: date, age: age, male: male, female: female),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final item = _entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MaleBirdsCard(entry: item),
            );
          },
        ),
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
        borderRadius: BorderRadius.circular(14),
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
                  child: Icon(Icons.male, color: Color(0xFF22C55E), size: 32),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ValueColumn(label: 'Age', value: entry.age),
              _VerticalDivider(),
              _ValueColumn(label: 'Male', value: entry.male),
              _VerticalDivider(),
              _ValueColumn(label: 'Female', value: entry.female),
            ],
          ),
        ],
      ),
    );
  }
}

class MaleBirdsEntry {
  final String date;
  final String age;
  final String male;
  final String female;
  MaleBirdsEntry({
    required this.date,
    required this.age,
    required this.male,
    required this.female,
  });
}

class _ValueColumn extends StatelessWidget {
  final String label;
  final String value;
  const _ValueColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 14, color: const Color(0xFFD1D5DB));
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
          fontSize: 14,
          color: Color(0xFF7A7A7A),
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 14,
              fontWeight: FontWeight.w800,
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
