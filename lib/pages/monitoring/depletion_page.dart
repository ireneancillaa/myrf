import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import 'depletion_input_page.dart';

class DepletionPage extends StatefulWidget {
  const DepletionPage({super.key});

  @override
  State<DepletionPage> createState() => _DepletionPageState();
}

class _DepletionPageState extends State<DepletionPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);

  late final BroilerController _controller;
  final List<DepletionEntry> _entries = [];

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

  Future<void> _openAddDepletion() async {
    final result = await Navigator.of(context).push<DepletionEntry>(
      MaterialPageRoute(builder: (_) => const DepletionInputPage()),
    );

    if (result == null) return;

    setState(() {
      _entries.insert(0, result);
    });
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
        centerTitle: true,
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
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final item = _entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _DepletionCard(entry: item),
                  );
                },
              ),
              Positioned(
                right: 18,
                bottom: 22,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openAddDepletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 30),
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
            ],
          ),
        );
      }),
    );
  }
}

class _DepletionCard extends StatelessWidget {
  const _DepletionCard({required this.entry});

  final DepletionEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCACACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Color(0xFFDFF3E2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/chicken.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.type == 'Cull' ? 'Culling' : entry.type,
                      style: const TextStyle(
                        color: Color(0xFF03A120),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.date,
                      style: const TextStyle(
                        color: Color(0xFF3E3E3E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
