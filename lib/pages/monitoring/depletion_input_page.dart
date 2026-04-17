import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DepletionEntry {
  const DepletionEntry({
    required this.type,
    required this.date,
    required this.age,
    required this.penNumber,
    required this.bodyWeight,
    this.remarks,
  });

  final String type;
  final String date;
  final String age;
  final String penNumber;
  final String bodyWeight;
  final String? remarks;
}

class DepletionInputPage extends StatefulWidget {
  const DepletionInputPage({super.key});

  @override
  State<DepletionInputPage> createState() => _DepletionInputPageState();
}

class _DepletionInputPageState extends State<DepletionInputPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _labelColor = Color(0xFF858991);
  static const Color _textColor = Color(0xFF111111);
  static const String _depletionIconAsset = 'assets/chicken.png';
  static const String _ageIconAsset = 'assets/chicken.png';
  static const String _bodyWeightIconAsset = 'assets/body-weight.png';
  static const String _remarksIconAsset = 'assets/remarks.png';
  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldLabelSize = 14;
  static const double _fieldHeight = 50;
  static const double _buttonTextSize = 16;
  static const double _buttonHeight = 50;

  final _dateController = TextEditingController();
  final _penNumberController = TextEditingController();
  final _bodyWeightController = TextEditingController();
  final _remarksController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedType;
  String? _penNumberError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _penNumberController.dispose();
    _bodyWeightController.dispose();
    _remarksController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _validatePenNumber(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return 'Pen Number must be a valid number';
    }
    if (parsed > 42) {
      return 'Max. 42';
    }
    return null;
  }

  void _onPenNumberChanged(String value) {
    setState(() {
      _penNumberError = _validatePenNumber(value);
    });
  }

  Future<void> _selectDate() async {
    final initialDate = _parseDate(_dateController.text) ?? _today();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date == null) return;

    final selectedDate = DateTime(date.year, date.month, date.day);
    setState(() {
      _dateController.text = _formatDate(selectedDate);
    });
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;

    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<String?> _showDropdownBottomSheet({
    required String title,
    required String hint,
    required List<String> options,
    required String? selectedValue,
  }) async {
    const modalTopRadius = 20.0;
    const optionRadius = 10.0;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(modalTopRadius),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(modalTopRadius),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedValue == null || selectedValue.isEmpty
                          ? 'Current: $hint'
                          : 'Current: $selectedValue',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = option == selectedValue;
                          return InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(option),
                            borderRadius: BorderRadius.circular(optionRadius),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEAF8EE)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  optionRadius,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF22C55E),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickType() async {
    final picked = await _showDropdownBottomSheet(
      title: 'Select Depletion Type',
      hint: 'Select Depletion Type',
      options: const ['Mortality', 'Culling'],
      selectedValue: _selectedType,
    );
    if (picked == null) return;
    setState(() {
      _selectedType = picked;
    });
  }

  void _submit() {
    if ((_selectedType ?? '').isEmpty) {
      _showMessage('Please select depletion type');
      return;
    }
    if (_dateController.text.trim().isEmpty) {
      _showMessage('Please select a date');
      return;
    }
    if (_penNumberController.text.trim().isEmpty) {
      _showMessage('Please enter pen number');
      return;
    }
    final penNumberError = _validatePenNumber(_penNumberController.text);
    if (penNumberError != null) {
      setState(() {
        _penNumberError = penNumberError;
      });
      return;
    }
    if (_bodyWeightController.text.trim().isEmpty) {
      _showMessage('Please enter body weight');
      return;
    }
    if (_ageController.text.trim().isEmpty) {
      _showMessage('Please enter age');
      return;
    }

    Navigator.of(context).pop(
      DepletionEntry(
        type: _selectedType!.trim(),
        date: _dateController.text.trim(),
        age: _ageController.text.trim(),
        penNumber: _penNumberController.text.trim(),
        bodyWeight: _bodyWeightController.text.trim(),
        remarks: _remarksController.text.trim(),
      ),
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _primaryGreen : const Color(0xFFEF4444),
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
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          ' New Depletion',
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildUnderlineSelectField(
                          label: 'Depletion Type',
                          value: _selectedType ?? '',
                          prefixAssetPath: _depletionIconAsset,
                          onTap: _pickType,
                          useCommonFieldStyle: true,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _buildUnderlineSelectField(
                                label: 'Date',
                                value: _dateController.text,
                                icon: Icons.calendar_month,
                                onTap: _selectDate,
                                showChevron: false,
                                useCommonFieldStyle: true,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                controller: _ageController,
                                label: 'Age',
                                hint: 'Age',
                                prefixAssetPath: _ageIconAsset,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _penNumberController,
                                label: 'Pen Number',
                                hint: 'Pen Number',
                                icon: Icons.grid_view_rounded,
                                keyboardType: TextInputType.number,
                                errorText: _penNumberError,
                                onChanged: _onPenNumberChanged,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                controller: _bodyWeightController,
                                label: 'Body Weight (g)',
                                hint: 'Body Weight (g)',
                                prefixAssetPath: _bodyWeightIconAsset,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildTextField(
                          controller: _remarksController,
                          label: 'Remarks',
                          hint: 'Remarks',
                          prefixAssetPath: _remarksIconAsset,
                          minLines: 1,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: _buttonHeight,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Depletion',
                      style: TextStyle(
                        fontSize: _buttonTextSize,
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

  Widget _buildUnderlineSelectField({
    required String label,
    required String value,
    IconData? icon,
    String? prefixAssetPath,
    required VoidCallback onTap,
    bool showChevron = true,
    bool useCommonFieldStyle = false,
  }) {
    if (useCommonFieldStyle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _fieldHeight),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: InputDecorator(
                isEmpty: value.trim().isEmpty,
                decoration:
                    _fieldDecoration(
                      hint: label,
                      icon: icon,
                      prefixAssetPath: prefixAssetPath,
                    ).copyWith(
                      suffixIcon: showChevron
                          ? const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: Color(0xFF6B7280),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: _fieldTextSize,
                    color: _textColor,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _primaryGreen, width: 1.0)),
        ),
        child: Row(
          children: [
            _buildPrefixIcon(icon: icon, assetPath: prefixAssetPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _labelColor,
                      fontSize: _fieldLabelSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '-' : value,
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: _fieldTextSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF111827),
                size: 30,
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? icon,
    String? prefixAssetPath,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: _fieldHintSize,
        color: Color(0xFF9CA3AF),
        height: 1.0,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 0, right: 8),
        child: prefixAssetPath != null
            ? Image.asset(
                prefixAssetPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              )
            : Icon(icon),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF22C55E), width: 1.0),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF22C55E), width: 1.0),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF22C55E), width: 1.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: _fieldLabelSize, color: _labelColor),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? prefixAssetPath,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final isNumericKeyboard =
        keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions() ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
        keyboardType == const TextInputType.numberWithOptions(signed: true) ||
        keyboardType ==
            const TextInputType.numberWithOptions(decimal: true, signed: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _fieldHeight),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            inputFormatters: isNumericKeyboard
                ? [FilteringTextInputFormatter.deny(RegExp(r'-'))]
                : null,
            minLines: minLines,
            maxLines: maxLines,
            style: const TextStyle(fontSize: _fieldTextSize, height: 1.0),
            onChanged: onChanged,
            decoration: _fieldDecoration(
              hint: hint,
              icon: icon,
              prefixAssetPath: prefixAssetPath,
            ).copyWith(errorText: errorText),
          ),
        ),
      ],
    );
  }

  Widget _buildPrefixIcon({IconData? icon, String? assetPath}) {
    return Container(
      width: 78 / 1.45,
      height: 78 / 1.45,
      decoration: const BoxDecoration(
        color: Color(0xFFD4DED4),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: assetPath != null
            ? Image.asset(assetPath, width: 24, height: 24, fit: BoxFit.contain)
            : Icon(
                icon ?? Icons.circle_outlined,
                color: _primaryGreen,
                size: 34,
              ),
      ),
    );
  }
}
