import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/broiler_controller.dart';
import '../../controller/infeed_controller.dart';
import '../../controller/weighing_controller.dart';
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
  late final WeighingController _weighingController;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);

    _infeedController = Get.isRegistered<InfeedController>()
        ? Get.find<InfeedController>()
        : Get.put(InfeedController(), permanent: true);

    _weighingController = Get.isRegistered<WeighingController>()
        ? Get.find<WeighingController>()
        : Get.put(WeighingController(), permanent: true);
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
    return _infeedController.penValuesByStage[stageIndex].isNotEmpty;
  }

  String _formatPenTotal(int stageIndex) {
    final values = _infeedController.penValuesByStage[stageIndex];
    if (values.isEmpty) return '-';

    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total % 1 == 0) {
      return total.toInt().toString();
    }
    return total.toStringAsFixed(2);
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
          initialDate: _infeedController.dateControllers[stageIndex].text,
          initialValues: _infeedController.penValuesByStage[stageIndex],
        ),
      ),
    );

    if (result == null) return;

    final values = (result['values'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => (value as num).toDouble())
        .toList();

    _infeedController.saveStage(
      stageIndex,
      (result['date'] ?? '').toString(),
      values,
    );
  }

  Future<void> _showStagePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Stage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_stageTitle(index)),
                      subtitle: Text(_stageRange(index)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _openStageEditor(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
      ),
      body: Obx(() {
        final project = _currentProject();
        if (project == null) {
          return const Center(child: Text('Please select a project first'));
        }

        // Get indices of stages that have data
        final stagesWithData = List.generate(
          9,
          (i) => i,
        ).where((i) => _stageHasData(i)).toList();

        if (stagesWithData.isEmpty) {
          return const EmptyStateWidget(moduleName: 'Infeed');
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: stagesWithData.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildStageCard(stagesWithData[index], project);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: _showStagePicker,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Infeed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStageCard(int stageIndex, BroilerProjectData project) {
    final updatedAt = _infeedController.stageUpdatedAt[stageIndex];
    final updatedAtText = updatedAt == null ? '-' : _formatTimestamp(updatedAt);
    final feedTotal = _formatPenTotal(stageIndex);

    // Get latest body weight from WeighingController
    String bodyWeight = '-';
    if (_weighingController.weighingHistory.isNotEmpty) {
      final latest = _weighingController.weighingHistory.first;
      bodyWeight = latest.weight;
    }

    return InkWell(
      onTap: () => _openStageEditor(stageIndex),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                        _stageTitle(stageIndex),
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
                            updatedAtText,
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
                      value: project.currentAge.toString(),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  flex: 18,
                  child: _MetricText(label: 'Pen', value: feedTotal),
                ),
                const _MetricDivider(),
                Expanded(
                  flex: 30,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: _MetricText(
                      label: 'Body Weight (g)',
                      value: bodyWeight,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
