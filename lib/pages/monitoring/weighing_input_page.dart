import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/weighing_controller.dart';
import '../../controller/broiler_controller.dart';
import 'weighing_calculator_page.dart';

class WeighingInputPage extends StatefulWidget {
  const WeighingInputPage({super.key});

  @override
  State<WeighingInputPage> createState() => _WeighingInputPageState();
}

class _WeighingInputPageState extends State<WeighingInputPage> {
  late final BroilerController _broilerController;
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);

  String? _dateError;
  String? _feedAndBagError;
  String? _lastBirdsError;
  String? _actualBirdsError;
  String? _birdsWeightError;

  late final WeighingController _weighingController;

  @override
  void initState() {
    super.initState();
    _weighingController = Get.find<WeighingController>();
    _broilerController = Get.find<BroilerController>();
    _weighingController.dateController.addListener(_updateAgeFromDate);
    // Inisialisasi age jika date sudah terisi
    if (_weighingController.dateController.text.isNotEmpty) {
      _updateAgeFromDate();
    }
  }

  @override
  void dispose() {
    _weighingController.dateController.removeListener(_updateAgeFromDate);
    super.dispose();
  }

  void _updateAgeFromDate() {
    final dateStr = _weighingController.dateController.text;
    final docInStr = _broilerController.docInDateController.text;
    if (dateStr.isEmpty || docInStr.isEmpty) {
      _weighingController.ageController.text = '';
      return;
    }
    try {
      // Format date: dd/MM/yyyy
      final inputParts = dateStr.split('/');
      final docInParts = docInStr.split('/');
      if (inputParts.length == 3 && docInParts.length == 3) {
        final inputDate = DateTime(
          int.parse(inputParts[2]),
          int.parse(inputParts[1]),
          int.parse(inputParts[0]),
        );
        final docInDate = DateTime(
          int.parse(docInParts[2]),
          int.parse(docInParts[1]),
          int.parse(docInParts[0]),
        );
        final age = inputDate.difference(docInDate).inDays + 1;
        _weighingController.ageController.text = age > 0 ? age.toString() : '1';
      } else {
        _weighingController.ageController.text = '';
      }
    } catch (_) {
      _weighingController.ageController.text = '';
    }
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      // Reset semua error sebelum divalidasi ulang
      _dateError = _weighingController.dateController.text.isEmpty
          ? 'Please select a date'
          : null;
      _feedAndBagError =
          (_weighingController.feedAndBagValue.value ?? '').isEmpty
          ? 'Input Feed & Bag required'
          : null;
      _lastBirdsError = (_weighingController.lastBirdsValue.value ?? '').isEmpty
          ? 'Input Last Birds required'
          : null;
      _actualBirdsError =
          (_weighingController.actualBirdsValue.value ?? '').isEmpty
          ? 'Input Actual Birds required'
          : null;
      _birdsWeightError =
          (_weighingController.birdsWeightValue.value ?? '').isEmpty
          ? 'Input Birds Weight required'
          : null;
    });

    // Jika ada salah satu error yang tidak null, batalkan submit
    if (_dateError != null ||
        _feedAndBagError != null ||
        _lastBirdsError != null ||
        _actualBirdsError != null ||
        _birdsWeightError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    await _weighingController.saveCurrentWeighing();
    Get.snackbar(
      'Success',
      'Weighing record saved',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _selectDate() async {
    final dateParts = _weighingController.dateController.text.split('/');
    DateTime initialDate = DateTime.now();
    if (dateParts.length == 3) {
      final day = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);
      if (day != null && month != null && year != null) {
        initialDate = DateTime(year, month, day);
      }
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF22C55E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF22C55E)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = date.month.toString().padLeft(2, '0');
      _weighingController.dateController.text =
          '$dayStr/$monthStr/${date.year}';
    }
  }

  void _onChecklistTap(String type) async {
    // Ambil initialValues dari RxList<String> dan konversi ke List<double>
    List<double> initialValues = [];
    String initialDate = _weighingController.dateController.text;
    switch (type) {
      case 'feedAndBag':
        if (_weighingController.feedAndBagPens.isNotEmpty) {
          initialValues = _weighingController.feedAndBagPens
              .map((e) => double.tryParse(e) ?? 0)
              .toList();
        } else if (_weighingController.feedAndBagValue.value != null) {
          final v = double.tryParse(_weighingController.feedAndBagValue.value!);
          if (v != null) initialValues = [v];
        }
        break;
      case 'lastBirds':
        if (_weighingController.lastBirdsPens.isNotEmpty) {
          initialValues = _weighingController.lastBirdsPens
              .map((e) => double.tryParse(e) ?? 0)
              .toList();
        } else if (_weighingController.lastBirdsValue.value != null) {
          final v = double.tryParse(_weighingController.lastBirdsValue.value!);
          if (v != null) initialValues = [v];
        }
        break;
      case 'actualBirds':
        if (_weighingController.actualBirdsPens.isNotEmpty) {
          initialValues = _weighingController.actualBirdsPens
              .map((e) => double.tryParse(e) ?? 0)
              .toList();
        } else if (_weighingController.actualBirdsValue.value != null) {
          final v = double.tryParse(
            _weighingController.actualBirdsValue.value!,
          );
          if (v != null) initialValues = [v];
        }
        break;
      case 'birdsWeight':
        if (_weighingController.birdsWeightPens.isNotEmpty) {
          initialValues = _weighingController.birdsWeightPens
              .map((e) => double.tryParse(e) ?? 0)
              .toList();
        } else if (_weighingController.birdsWeightValue.value != null) {
          final v = double.tryParse(
            _weighingController.birdsWeightValue.value!,
          );
          if (v != null) initialValues = [v];
        }
        break;
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => WeighingCalculatorPage(
          calcType: type,
          initialDate: initialDate,
          initialValues: initialValues,
        ),
      ),
    );
    if (result != null && result['values'] is List) {
      final values = (result['values'] as List).cast<double>();
      final pens = (result['pens'] as List?)?.cast<String>() ?? [];
      final total = values.fold<double>(0, (sum, v) => sum + v);
      // Format total: integer tanpa .00, desimal 2 digit
      String totalStr;
      if (total == 0) {
        totalStr = '-';
      } else if (total % 1 == 0) {
        totalStr = total.toInt().toString();
      } else {
        totalStr = total.toStringAsFixed(2);
      }
      switch (type) {
        case 'feedAndBag':
          _weighingController.feedAndBagValue.value = totalStr;
          _weighingController.feedAndBagPens.assignAll(pens);
          break;
        case 'lastBirds':
          _weighingController.lastBirdsValue.value = totalStr;
          _weighingController.lastBirdsPens.assignAll(pens);
          break;
        case 'actualBirds':
          _weighingController.actualBirdsValue.value = totalStr;
          _weighingController.actualBirdsPens.assignAll(pens);
          break;
        case 'birdsWeight':
          _weighingController.birdsWeightValue.value = totalStr;
          _weighingController.birdsWeightPens.assignAll(pens);
          break;
      }
    }
  }

  void _onAddBoxTap() async {
    String? initialFromPen;
    if (_weighingController.boxWeights.isNotEmpty) {
      final lastBox = _weighingController.boxWeights.last;
      // title format: "Pen $start - $end"
      final parts = lastBox.title.split(' - ');
      if (parts.length == 2) {
        final lastEndStr = parts[1];
        final lastEnd = int.tryParse(lastEndStr);
        if (lastEnd != null) {
          initialFromPen = (lastEnd + 1).toString();
        }
      }
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => WeighingCalculatorPage(
          calcType: 'boxWeight',
          initialFromPen: initialFromPen,
        ),
      ),
    );

    if (result != null) {
      final title = result['title'] as String;
      final count = result['count'] as int;
      final weight = result['weight'] as double;

      _weighingController.boxWeights.add(
        BoxWeight(title: title, count: count, weight: weight),
      );
    }
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
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'New Weighing',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildUnderlineField(
                      icon: Icons.calendar_month,
                      label: 'Date',
                      hintText: 'Date',
                      controller: _weighingController.dateController,
                      readOnly: true,
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildUnderlineField(
                      icon: Icons.pets,
                      prefixAssetPath: 'assets/age.png',
                      iconColor: const Color(0xFF6B7280),
                      label: 'Age',
                      hintText: 'Age',
                      controller: _weighingController.ageController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Box Weight'),
              const SizedBox(height: 12),
              Obx(
                () => Column(
                  children: [
                    ..._weighingController.boxWeights.map(
                      (box) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBoxCard(box),
                      ),
                    ),
                    _buildAddBoxButton(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Weight'),
              const SizedBox(height: 12),
              Obx(
                () => Column(
                  children: [
                    _buildChecklistItem(
                      title: 'Feed & Bag',
                      value: _weighingController.feedAndBagValue.value,
                      unit: 'kg',
                      onTap: () => _onChecklistTap('feedAndBag'),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      title: 'Last Birds',
                      value: _weighingController.lastBirdsValue.value,
                      unit: '',
                      onTap: () => _onChecklistTap('lastBirds'),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      title: 'Actual Birds',
                      value: _weighingController.actualBirdsValue.value,
                      unit: '',
                      onTap: () => _onChecklistTap('actualBirds'),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      title: 'Birds Weight',
                      value: _weighingController.birdsWeightValue.value,
                      unit: 'kg',
                      onTap: () => _onChecklistTap('birdsWeight'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save Weighing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _primaryGreen,
      ),
    );
  }

  Widget _buildUnderlineField({
    IconData? icon,
    String? prefixAssetPath,
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.only(bottom: 2), // Spacing for underline
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF22C55E), width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: prefixAssetPath != null
                  ? (prefixAssetPath.endsWith('.svg')
                        ? SvgPicture.asset(
                            prefixAssetPath,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            prefixAssetPath,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ))
                  : Icon(
                      icon,
                      color: iconColor ?? const Color(0xFF22C55E),
                      size: 32,
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF858991),
                    ),
                  ),
                  TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap, // Keep this for keyboard accessibility
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111111),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String? value,
    required String unit,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty && value != '-';
    final nowStr = DateFormat('dd MMM yyyy - HH:mm:ss').format(DateTime.now());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _primaryGreen : const Color(0xFFE0E0E0),
            width: hasValue ? 1.4 : 1,
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
                  color: hasValue ? _primaryGreen : const Color(0xFF8A8A8A),
                ),
                color: hasValue ? _primaryGreen : Colors.transparent,
              ),
              child: hasValue
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? _primaryGreen : const Color(0xFF6F6F6F),
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
                        hasValue ? nowStr : '-',
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
            _buildChecklistBadge(
              hasValue ? '$value $unit'.trim() : '-',
              hasValue: hasValue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistBadge(String value, {required bool hasValue}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasValue ? const Color(0xFFECFDF3) : const Color(0xFFF6F6F6),
        border: Border.all(
          color: hasValue ? const Color(0xFF86EFAC) : const Color(0xFFE0E0E0),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasValue ? _primaryGreen : const Color(0xFF6F6F6F),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBoxCard(BoxWeight box) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/box.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  box.title,
                  style: const TextStyle(
                    color: _primaryGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Box ',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    Text(
                      '${box.count}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 12,
                      color: const Color(0xFF7D7D7D),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Box Weight (kg) ',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    Text(
                      '${box.weight % 1 == 0 ? box.weight.toInt() : box.weight}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBoxButton() {
    return InkWell(
      onTap: _onAddBoxTap,
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: _primaryGreen,
          strokeWidth: 1.2,
          gap: 5,
        ),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Add Box',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(10),
        ),
      );

    for (final PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + gap),
          paint,
        );
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
