import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:myrf/pages/monitoring/weighing_input_page.dart';

import '../../controller/weighing_controller.dart';

import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/empty_state_widget.dart';

const Color primaryGreen = Color(0xFF22C55E);
const Color textPrimary = Color(0xFF111827);

class WeighingPage extends StatefulWidget {
  const WeighingPage({super.key, this.selectedFarmName});

  final String? selectedFarmName;

  @override
  State<WeighingPage> createState() => _WeighingPageState();
}

class _WeighingPageState extends State<WeighingPage> {
  Widget _buildWeighingCard(WeighingRecord record) {
    final dateStr = DateFormat('dd MMM yyyy - HH:mm:ss').format(record.recordedAt);
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
                    'assets/body-weight.png',
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
                    const Text(
                      'Weighing',
                      style: TextStyle(
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
                          dateStr,
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
                  value: record.age,
                  textAlign: TextAlign.left,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MetricText(
                  label: 'Feed',
                  value: record.feed,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MetricText(
                  label: 'Birds',
                  value: record.birds,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MetricText(
                  label: 'Weight',
                  value: record.weight,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  late final WeighingController _weighingController;

  @override
  void initState() {
    super.initState();

    _weighingController = Get.isRegistered<WeighingController>()
        ? Get.find<WeighingController>()
        : Get.put(WeighingController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'Weighing',
          style: TextStyle(
            color: textPrimary,
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
              icon: const Icon(Icons.picture_as_pdf, color: textPrimary),
              tooltip: 'Export PDF',
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_weighingController.weighingHistory.isEmpty) {
          return const EmptyStateWidget(moduleName: 'Weighing');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _weighingController.weighingHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final record = _weighingController.weighingHistory[index];
            return Dismissible(
              key: ValueKey(record.recordedAt.toIso8601String()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                return await DeleteConfirmationDialog.show(
                  title: 'Delete Data?',
                  message: 'This weighing data will be deleted permanently. Continue?',
                  onConfirm: () {},
                );
              },
              onDismissed: (_) {
                _weighingController.deleteWeighing(record.id, record.age);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: const Color(0xFFEF4444),
                child: const Icon(Icons.delete, color: Colors.white, size: 32),
              ),
              child: _buildWeighingCard(record),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ),
        ),
        onPressed: () async {
          _weighingController.initNewWeighing();
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const WeighingInputPage()),
          );

          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Weighing record saved successfully'),
                backgroundColor: Color(0xFF22C55E),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Weighing',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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
