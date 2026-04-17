import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';
import 'infeed_input_page.dart';

class InfeedPage extends StatefulWidget {
  const InfeedPage({super.key});

  @override
  State<InfeedPage> createState() => _InfeedPageState();
}

class _InfeedPageState extends State<InfeedPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const double _cardMinHeight = 70;

  late final BroilerController _controller;

  final _dateControllers = List.generate(9, (_) => TextEditingController());
  final _penValuesByStage = List<List<double>>.generate(9, (_) => <double>[]);
  final _stageUpdatedAt = List<DateTime?>.filled(9, null);

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
  }

  @override
  void dispose() {
    for (final controller in _dateControllers) {
      controller.dispose();
    }
    super.dispose();
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

  String _stageTitle(int stageIndex) {
    switch (stageIndex) {
      case 0:
        return 'Pre Starter 1';
      case 1:
        return 'Pre Starter 2';
      case 2:
        return 'Starter 1';
      case 3:
        return 'Starter 2';
      case 4:
        return 'Starter 3';
      case 5:
        return 'Finisher 1';
      case 6:
        return 'Finisher 2';
      case 7:
        return 'Finisher 3';
      default:
        return 'Finisher 4';
    }
  }

  String _stageGroup(int stageIndex) {
    switch (stageIndex) {
      case 0:
      case 1:
        return 'Pre Starter';
      case 2:
      case 3:
      case 4:
        return 'Starter';
      default:
        return 'Finisher';
    }
  }

  String _stageRange(int stageIndex) {
    switch (stageIndex) {
      case 0:
      case 1:
        return '0-10 days';
      case 2:
      case 3:
      case 4:
        return '11-21 days';
      default:
        return '22-45 days';
    }
  }

  bool _stageHasData(int stageIndex) {
    return _penValuesByStage[stageIndex].isNotEmpty;
  }

  String _formatPenTotal(int stageIndex) {
    final values = _penValuesByStage[stageIndex];
    if (values.isEmpty) return '-';

    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total % 1 == 0) {
      return '${total.toInt()} kg';
    }
    return '${total.toStringAsFixed(2)} kg';
  }

  String _formatTimestamp(DateTime value) {
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
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$day ${monthNames[value.month - 1]} ${value.year} - $hour:$minute:$second';
  }

  Future<void> _openStageEditor(int stageIndex) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => InfeedInputPage(
          stageTitle: _stageTitle(stageIndex),
          stageGroup: _stageGroup(stageIndex),
          stageRange: _stageRange(stageIndex),
          initialDate: _dateControllers[stageIndex].text,
          initialValues: _penValuesByStage[stageIndex],
        ),
      ),
    );

    if (result == null) return;

    final values = (result['values'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => (value as num).toDouble())
        .toList();

    setState(() {
      _dateControllers[stageIndex].text = (result['date'] ?? '').toString();
      _penValuesByStage[stageIndex]
        ..clear()
        ..addAll(values);
      if (_penValuesByStage[stageIndex].isNotEmpty) {
        _stageUpdatedAt[stageIndex] = DateTime.now();
      }
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
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'Infeed',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Obx(() {
          final project = _currentProject();
          if (project == null) {
            return const Center(child: Text('Please select a project first'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildStageCard(0),
              const SizedBox(height: 14),
              _buildStageCard(1),
              const SizedBox(height: 14),
              _buildStageCard(2),
              const SizedBox(height: 14),
              _buildStageCard(3),
              const SizedBox(height: 14),
              _buildStageCard(4),
              const SizedBox(height: 14),
              _buildStageCard(5),
              const SizedBox(height: 14),
              _buildStageCard(6),
              const SizedBox(height: 14),
              _buildStageCard(7),
              const SizedBox(height: 14),
              _buildStageCard(8),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStageCard(int stageIndex) {
    final hasData = _stageHasData(stageIndex);
    final titleColor = hasData ? _primaryGreen : const Color(0xFF6F6F6F);
    final updatedAt = _stageUpdatedAt[stageIndex];
    final updatedAtText = updatedAt == null ? '-' : _formatTimestamp(updatedAt);
    final badgeValue = _formatPenTotal(stageIndex);

    return InkWell(
      onTap: () => _openStageEditor(stageIndex),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: _cardMinHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasData ? _primaryGreen : const Color(0xFFE0E0E0),
            width: hasData ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasData ? _primaryGreen : const Color(0xFF8A8A8A),
                ),
                color: hasData ? _primaryGreen : Colors.transparent,
              ),
              child: hasData
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stageTitle(stageIndex),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        updatedAtText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildStageBadge(badgeValue, hasData: hasData),
          ],
        ),
      ),
    );
  }

  Widget _buildStageBadge(String value, {required bool hasData}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasData ? const Color(0xFFECFDF3) : const Color(0xFFF6F6F6),
        border: Border.all(
          color: hasData ? const Color(0xFF86EFAC) : const Color(0xFFE0E0E0),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasData ? value : '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasData ? _primaryGreen : const Color(0xFF6F6F6F),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
