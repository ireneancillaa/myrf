import 'package:flutter/material.dart';
import 'package:myrf/pages/monitoring/feses_score_calculator_page.dart';

import '../../controller/feses_controller.dart';

class FesesScoreInputPage extends StatefulWidget {
  const FesesScoreInputPage({super.key});

  @override
  State<FesesScoreInputPage> createState() => _FesesScoreInputPageState();
}

class _FesesScoreInputPageState extends State<FesesScoreInputPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textColor = Color(0xFF111111);
  static const double _cardMinHeight = 70;

  final List<TextEditingController> _controllers = [];
  final TextEditingController _codeController = TextEditingController();
  String? _codeError;
  final List<String> _labels = const ['Feses', 'Cawan', 'Oven'];
  final List<List<double>> _fieldPenValues = [[], [], []];
  final List<DateTime?> _fieldUpdatedAt = List<DateTime?>.filled(3, null);

  @override
  void initState() {
    super.initState();
    _controllers.addAll([
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]);
  }

  @override
  void dispose() {
    _codeController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
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

  bool _fieldHasData(int index) => _fieldPenValues[index].isNotEmpty;

  String _formatUpdatedAt(DateTime? value) {
    if (value == null) return '-';
    return _formatDateTime(value);
  }

  String _fieldBadgeValue(int index) {
    if (!_fieldHasData(index)) return '-';
    return '${_formatValue(_controllers[index].text)} kg';
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

    Navigator.of(context).pop(
      FesesScoreEntry(
        date: _formatDateTime(DateTime.now()),
        penNumber: code,
        fesesKg: fesesKg,
        cawanKg: cawanKg,
        ovenKg: ovenKg,
        totalKg: totalKg,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                _buildHeaderField(),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: _labels.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _buildFieldCard(index),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Feses Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 2), // Spacing for underline
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _codeError != null ? const Color(0xFFEF4444) : const Color(0xFF22C55E), 
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Enlarged and vertically centered Icon Box
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.asset(
                  'assets/remarks.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
              // Label and textfield side-by-side with icon
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kode Cawan',
                      style: TextStyle(fontSize: 14, color: Color(0xFF858991)),
                    ),
                    TextField(
                      controller: _codeController,
                      onChanged: (val) {
                        if (_codeError != null && val.trim().isNotEmpty) {
                          setState(() {
                            _codeError = null;
                          });
                        }
                      },
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        hintText: 'Kode Cawan',
                        hintStyle: TextStyle(
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
        if (_codeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 44),
            child: Text(
              _codeError!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldCard(int index) {
    final hasData = _fieldHasData(index);
    final titleColor = hasData ? _primaryGreen : const Color(0xFF6F6F6F);

    return InkWell(
      onTap: () => _pickValue(index),
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
                    _labels[index],
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
                        _formatUpdatedAt(_fieldUpdatedAt[index]),
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
            _buildFieldBadge(_fieldBadgeValue(index), hasData: hasData),
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
