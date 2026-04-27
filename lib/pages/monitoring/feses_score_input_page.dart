import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:myrf/pages/monitoring/feses_score_calculator_page.dart';

import '../../controller/feses_controller.dart';
import '../../controller/broiler_controller.dart';

class FesesScoreInputPage extends StatefulWidget {
  const FesesScoreInputPage({super.key});

  @override
  State<FesesScoreInputPage> createState() => _FesesScoreInputPageState();
}

class _FesesScoreInputPageState extends State<FesesScoreInputPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textColor = Color(0xFF111111);
  static const double _cardMinHeight = 70;

  late final BroilerController _broilerController;
  late final FesesController _fesesController;

  final List<TextEditingController> _controllers = [];
  final TextEditingController _codeController = TextEditingController();
  String? _codeError;
  final List<String> _labels = const ['Feses', 'Cawan', 'Oven'];
  final List<List<double>> _fieldPenValues = [[], [], []];
  final List<DateTime?> _fieldUpdatedAt = List<DateTime?>.filled(3, null);

  List<double> _codeValues = [];
  DateTime? _codeUpdatedAt;

  @override
  void initState() {
    super.initState();
    _fesesController = Get.find<FesesController>();
    _broilerController = Get.find<BroilerController>();

    _fesesController.initNewFesesScore();
    _fesesController.dateController.addListener(_updateAgeFromDate);

    _controllers.addAll([
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]);

    if (_fesesController.dateController.text.isNotEmpty) {
      _updateAgeFromDate();
    }
  }

  @override
  void dispose() {
    _fesesController.dateController.removeListener(_updateAgeFromDate);
    _codeController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateAgeFromDate() {
    final dateStr = _fesesController.dateController.text;
    final docInStr = _broilerController.docInDateController.text;
    if (dateStr.isEmpty || docInStr.isEmpty) {
      _fesesController.ageController.text = '';
      return;
    }
    try {
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
        _fesesController.ageController.text = age > 0 ? age.toString() : '1';
      } else {
        _fesesController.ageController.text = '';
      }
    } catch (_) {
      _fesesController.ageController.text = '';
    }
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
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$day ${monthNames[value.month - 1]} ${value.year} - $hour:$minute:$second';
  }

  double _parseKg(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || parsed <= 0) return 0;
    return parsed;
  }

  double _sumPenValues(List<double> values) {
    var total = 0.0;
    for (final value in values) {
      if (value > 0) {
        total += value;
      }
    }
    return total;
  }

  Future<void> _pickValue(int index) async {
    final result = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (_) => FesesScoreCalculatorPage(
          fieldLabel: _labels[index],
          initialValues: _fieldPenValues[index],
        ),
      ),
    );

    if (result == null) return;

    final totalValue = _sumPenValues(result);
    setState(() {
      _fieldPenValues[index] = result;
      _controllers[index].text = totalValue == 0
          ? ''
          : totalValue.toStringAsFixed(3);
      _fieldUpdatedAt[index] = result.isEmpty ? null : DateTime.now();
    });
  }

  Future<void> _pickCode() async {
    final result = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (_) => FesesScoreCalculatorPage(
          fieldLabel: 'Kode Cawan',
          initialValues: _codeValues,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _codeValues = result;
      if (result.isNotEmpty) {
        _codeController.text = result
            .map((e) => e % 1 == 0 ? e.toInt().toString() : e.toString())
            .join(', ');
        _codeUpdatedAt = DateTime.now();
        _codeError = null;
      } else {
        _codeController.clear();
        _codeUpdatedAt = null;
      }
    });
  }

  Future<void> _selectDate() async {
    final dateParts = _fesesController.dateController.text.split('/');
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
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _primaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = date.month.toString().padLeft(2, '0');
      _fesesController.dateController.text = '$dayStr/$monthStr/${date.year}';
    }
  }

  bool _fieldHasData(int index) => _fieldPenValues[index].isNotEmpty;

  String _formatUpdatedAt(DateTime? value) {
    if (value == null) return '-';
    return _formatDateTime(value);
  }

  String _fieldBadgeValue(int index) {
    if (!_fieldHasData(index)) return '-';
    return '${_formatValue(_controllers[index].text)} g';
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _primaryGreen : const Color(0xFFEF4444),
      ),
    );
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _codeError = 'Please select kode cawan';
      });
      return;
    } else {
      setState(() {
        _codeError = null;
      });
    }

    if (_controllers[0].text.trim().isEmpty) {
      _showMessage('Please input Feses value');
      return;
    }
    if (_controllers[1].text.trim().isEmpty) {
      _showMessage('Please input Cawan value');
      return;
    }
    if (_controllers[2].text.trim().isEmpty) {
      _showMessage('Please input Oven value');
      return;
    }

    final fesesKg = _parseKg(_controllers[0].text);
    final cawanKg = _parseKg(_controllers[1].text);
    final ovenKg = _parseKg(_controllers[2].text);
    final totalKg = fesesKg + cawanKg + ovenKg;

    // Parse selected date from dd/MM/yyyy to combine with current time
    DateTime finalDate;
    try {
      final parts = _fesesController.dateController.text.split('/');
      final pickedDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final now = DateTime.now();
      finalDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        now.hour,
        now.minute,
        now.second,
      );
    } catch (_) {
      finalDate = DateTime.now();
    }

    _fesesController.addFesesScore(
      FesesScoreEntry(
        date: finalDate.toIso8601String(),
        age: _fesesController.ageController.text.isNotEmpty
            ? _fesesController.ageController.text
            : '-',
        penNumber: code,
        fesesKg: fesesKg,
        cawanKg: cawanKg,
        ovenKg: ovenKg,
        totalKg: totalKg,
        recordedAt: DateTime.now(),
      ),
    );

    Get.snackbar(
      'Success',
      'Feses Score record saved',
      backgroundColor: _primaryGreen,
      colorText: Colors.white,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textColor),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'New Feses Score',
          style: TextStyle(
            color: _textColor,
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
                      controller: _fesesController.dateController,
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
                      controller: _fesesController.ageController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Kode Cawan'),
              const SizedBox(height: 12),
              _buildHeaderField(),
              const SizedBox(height: 24),
              _buildSectionTitle('Feses Score Input'),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _labels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _buildFieldCard(index),
              ),
              const SizedBox(height: 16), // Bottom spacing for list
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
              'Save Feses Score',
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

  Widget _buildInputCard({
    required VoidCallback onTap,
    required bool hasData,
    required String title,
    required DateTime? updatedAt,
    bool showError = false,
    Widget? iconWidget,
    Widget? trailingWidget,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: _cardMinHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasData
                ? _primaryGreen
                : (showError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE0E0E0)),
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
            if (iconWidget != null) ...[iconWidget, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: hasData ? _primaryGreen : const Color(0xFF6F6F6F),
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
                        _formatUpdatedAt(updatedAt),
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
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderField() {
    final hasData = _codeController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputCard(
          onTap: _pickCode,
          hasData: hasData,
          title: hasData ? _codeController.text : 'Kode Cawan',
          updatedAt: _codeUpdatedAt,
          showError: _codeError != null,
          iconWidget: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5EE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/remarks.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (_codeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 14),
            child: Text(
              _codeError!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldCard(int index) {
    final hasData = _fieldHasData(index);
    return _buildInputCard(
      onTap: () => _pickValue(index),
      hasData: hasData,
      title: _labels[index],
      updatedAt: _fieldUpdatedAt[index],
      trailingWidget: _buildFieldBadge(
        _fieldBadgeValue(index),
        hasData: hasData,
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
        padding: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _primaryGreen, width: 1.0)),
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
                  : Icon(icon, color: iconColor ?? _primaryGreen, size: 32),
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
                    onTap: onTap,
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

  Widget _buildFieldBadge(String value, {required bool hasData}) {
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

  String _formatValue(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return '-';
    if (parsed % 1 == 0) {
      return parsed.toInt().toStringAsFixed(0);
    }
    return parsed.toStringAsFixed(3);
  }
}
