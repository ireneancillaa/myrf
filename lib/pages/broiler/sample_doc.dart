import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sample_doc_input_page.dart';

class SampleDocSection extends StatefulWidget {
  final TextEditingController boxHeaviestController;
  final TextEditingController boxAverageController;
  final TextEditingController boxLightestController;
  final List<double> docWeights;
  final Function(List<double>) onDocWeightsChanged;
  final List<List<double>> sampleGroups;
  final Function(List<List<double>>) onSampleGroupsChanged;
  final List<Map<String, dynamic>> docDistributions;
  final Function(List<Map<String, dynamic>>) onDocDistributionsChanged;
  final int dietReplication;
  final int totalPens;

  const SampleDocSection({
    super.key,
    required this.boxHeaviestController,
    required this.boxAverageController,
    required this.boxLightestController,
    required this.docWeights,
    required this.onDocWeightsChanged,
    required this.sampleGroups,
    required this.onSampleGroupsChanged,
    required this.docDistributions,
    required this.onDocDistributionsChanged,
    required this.dietReplication,
    required this.totalPens,
  });

  @override
  State<SampleDocSection> createState() => _SampleDocSectionState();
}

class _SampleDocSectionState extends State<SampleDocSection> {
  static const double _sampleCardMinHeight = 70;
  static const double _sampleCountCircleSize = 50;

  final List<List<double>> _sampleDocWeights = [[], [], []];
  final List<DateTime?> _sampleUpdatedAt = [null, null, null];

  @override
  void initState() {
    super.initState();
    final hasGroupedData = widget.sampleGroups.any((item) => item.isNotEmpty);
    if (hasGroupedData) {
      for (int i = 0; i < _sampleDocWeights.length; i++) {
        _sampleDocWeights[i].addAll(
          i < widget.sampleGroups.length
              ? List<double>.from(widget.sampleGroups[i])
              : <double>[],
        );
        if (_sampleDocWeights[i].isNotEmpty) {
          _sampleUpdatedAt[i] = DateTime.now();
        }
      }
      return;
    }

    if (widget.docWeights.isNotEmpty) {
      for (int i = 0; i < widget.docWeights.length && i < 3; i++) {
        _sampleDocWeights[i].add(widget.docWeights[i]);
        if (widget.docWeights[i] > 0) {
          _sampleUpdatedAt[i] = DateTime.now();
        }
      }
    }
  }

  void _updateAllDocWeights() {
    final allWeights = <double>[];
    for (final sample in _sampleDocWeights) {
      allWeights.addAll(sample);
    }
    widget.onDocWeightsChanged(allWeights);
    widget.onSampleGroupsChanged(
      _sampleDocWeights.map((item) => List<double>.from(item)).toList(),
    );
  }

  Future<void> _openSampleInputPage(int sampleIndex) async {
    final result = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (_) => SampleDocInputPage(
          sampleNumber: sampleIndex + 1,
          initialWeights: List<double>.from(_sampleDocWeights[sampleIndex]),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _sampleDocWeights[sampleIndex]
        ..clear()
        ..addAll(result);
      _sampleUpdatedAt[sampleIndex] = result.isEmpty ? null : DateTime.now();
    });
    _updateAllDocWeights();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample DOC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Input the amount of DOC arrived at the farm (3 samples required)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildBoxSummaryRow(),
            const SizedBox(height: 18),
            ...List.generate(3, (index) => _buildSampleStatusCard(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleStatusCard(int index) {
    final hasData = _sampleDocWeights[index].isNotEmpty;
    final totalWeight = _sampleDocWeights[index].fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final isLastSample = index == _sampleDocWeights.length - 1;
    final titleColor = hasData
        ? const Color(0xFF08A81B)
        : const Color(0xFF6F6F6F);
    final updatedAtText = _sampleUpdatedAt[index] == null
        ? '-'
        : _formatDateTime(_sampleUpdatedAt[index]!);

    return Container(
      margin: EdgeInsets.only(bottom: isLastSample ? 0 : 16),
      child: InkWell(
        onTap: () => _openSampleInputPage(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: _sampleCardMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasData
                  ? const Color(0xFF08B32A)
                  : const Color(0xFFE0E0E0),
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
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: hasData
                        ? const Color(0xFF08B32A)
                        : const Color(0xFF8A8A8A),
                  ),
                  color: hasData ? const Color(0xFF08B32A) : Colors.transparent,
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
                      'Sample ${index + 1}',
                      style: TextStyle(
                        fontSize: 38 / 2,
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
              Container(
                width: _sampleCountCircleSize,
                height: _sampleCountCircleSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFD6E3D8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  hasData ? _formatTotalWeight(totalWeight) : '-',
                  style: TextStyle(
                    color: hasData
                        ? const Color(0xFF08A81B)
                        : const Color(0xFF6F6F6F),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildBoxInputCard(
            title: 'Heaviest',
            controller: widget.boxHeaviestController,
            icon: Icons.arrow_upward,
            color: const Color(0xFFF34235),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBoxInputCard(
            title: 'Average',
            controller: widget.boxAverageController,
            icon: Icons.remove,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBoxInputCard(
            title: 'Lightest',
            controller: widget.boxLightestController,
            icon: Icons.arrow_downward,
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime value) {
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
    final month = monthNames[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$day $month ${value.year} - $hour:$minute:$second';
  }

  String _formatTotalWeight(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildBoxInputCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 24 / 2,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,1}(\.\d{0,2})?'),
                ),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34 / 2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: color.withOpacity(0.35),
                  fontSize: 34 / 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
