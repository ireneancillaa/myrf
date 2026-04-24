import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myrf/pages/monitoring/male_birds_input_page.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import '../../controller/male_birds_controller.dart';

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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MaleBirdsInputPage(),
      ),
    );
  }

  Future<bool> _confirmDelete(MaleBirdsEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delete Data?',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This data will be permanently deleted. Continue?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: const Color(0xFF374151),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return confirmed ?? false;
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
                child: Dismissible(
                  key: ValueKey(item.id.isEmpty ? item.recordedAt.toIso8601String() : item.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(item),
                  onDismissed: (_) {
                    _maleBirdsController.deleteMaleBirds(item.id);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  child: _MaleBirdsCard(
                    entry: item,
                  ),
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
