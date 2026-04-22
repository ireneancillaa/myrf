import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controller/broiler_controller.dart';
import '../../controller/mortality_controller.dart';


class MortalityInputPage extends StatefulWidget {
  const MortalityInputPage({super.key});

  @override
  State<MortalityInputPage> createState() => _MortalityInputPageState();
}

class _MortalityInputPageState extends State<MortalityInputPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textColor = Color(0xFF111111);
  static const String _depletionIconAsset = 'assets/chicken.png';
  static const String _genderIconAsset = 'assets/gender.svg';
  static const String _ageIconAsset = 'assets/chicken.png';
  static const String _bodyWeightIconAsset = 'assets/body-weight.png';
  static const String _remarksIconAsset = 'assets/remarks.png';
  static const double _buttonTextSize = 16;
  static const double _buttonHeight = 50;

  final _dateController = TextEditingController();
  final _penNumberController = TextEditingController();
  final _bodyWeightController = TextEditingController();
  final _remarksController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedType;
  String? _selectedGender;
  String? _penNumberError;
  String? _typeError;
  String? _genderError;
  String? _dateError;
  String? _bodyWeightError;
  String? _ageError;

  final BroilerController _broilerController = Get.find<BroilerController>();

  @override
  void initState() {
    super.initState();
    _dateController.addListener(_updateAgeFromDate);
  }

  @override
  void dispose() {
    _dateController.removeListener(_updateAgeFromDate);
    _dateController.dispose();
    _penNumberController.dispose();
    _bodyWeightController.dispose();
    _remarksController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updateAgeFromDate() {
    final inputDate = _parseDate(_dateController.text);
    final docInDateStr = _broilerController.selectedDocInDate.value;
    if (inputDate == null || docInDateStr == null || docInDateStr.isEmpty) {
      _ageController.text = '';
      setState(() {});
      return;
    }
    final docInParts = docInDateStr.split('/');
    if (docInParts.length != 3) {
      _ageController.text = '';
      setState(() {});
      return;
    }
    final docInDay = int.tryParse(docInParts[0]);
    final docInMonth = int.tryParse(docInParts[1]);
    final docInYear = int.tryParse(docInParts[2]);
    if (docInDay == null || docInMonth == null || docInYear == null) {
      _ageController.text = '';
      setState(() {});
      return;
    }
    final docInDate = DateTime(docInYear, docInMonth, docInDay);
    final diff = inputDate.difference(docInDate).inDays + 1;
    _ageController.text = diff > 0 ? diff.toString() : '';
    setState(() {});
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
      _dateError = null;
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
      _typeError = null;
    });
  }

  Future<void> _pickGender() async {
    final picked = await _showDropdownBottomSheet(
      title: 'Select Gender',
      hint: 'Select Gender',
      options: const ['Male', 'Female'],
      selectedValue: _selectedGender,
    );
    if (picked == null) return;
    setState(() {
      _selectedGender = picked;
      _genderError = null;
    });
  }

  void _submit() {
    bool hasError = false;
    
    if ((_selectedType ?? '').isEmpty) {
      _typeError = 'Please select type';
      hasError = true;
    } else {
      _typeError = null;
    }
    
    if ((_selectedGender ?? '').isEmpty) {
      _genderError = 'Please select gender';
      hasError = true;
    } else {
      _genderError = null;
    }
    
    if (_dateController.text.trim().isEmpty) {
      _dateError = 'Please select a date';
      hasError = true;
    } else {
      _dateError = null;
    }
    
    if (_penNumberController.text.trim().isEmpty) {
      _penNumberError = 'Please enter pen number';
      hasError = true;
    } else {
      final pnError = _validatePenNumber(_penNumberController.text);
      if (pnError != null) {
        _penNumberError = pnError;
        hasError = true;
      } else {
        _penNumberError = null;
      }
    }
    
    if (_bodyWeightController.text.trim().isEmpty) {
      _bodyWeightError = 'Please enter body weight';
      hasError = true;
    } else {
      _bodyWeightError = null;
    }
    
    if (_ageController.text.trim().isEmpty) {
      _ageError = 'Please enter age';
      hasError = true;
    } else {
      _ageError = null;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      DepletionEntry(
        type: _selectedType!.trim(),
        gender: _selectedGender!.trim(),
        date: DateTime.now().toIso8601String(),
        age: _ageController.text.trim(),
        penNumber: _penNumberController.text.trim(),
        bodyWeight: _bodyWeightController.text.trim(),
        remarks: _remarksController.text.trim(),
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
                          errorText: _typeError,
                        ),
                        const SizedBox(height: 18),
                        _buildUnderlineSelectField(
                          label: 'Gender',
                          value: _selectedGender ?? '',
                          prefixAssetPath: _genderIconAsset,
                          onTap: _pickGender,
                          useCommonFieldStyle: true,
                          errorText: _genderError,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildUnderlineSelectField(
                                label: 'Date',
                                value: _dateController.text,
                                icon: Icons.calendar_month,
                                onTap: _selectDate,
                                showChevron: false,
                                useCommonFieldStyle: true,
                                errorText: _dateError,
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
                                readOnly: true,
                                errorText: _ageError,
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
                                errorText: _bodyWeightError,
                                onChanged: (_) {
                                  if (_bodyWeightError != null) setState(() => _bodyWeightError = null);
                                },
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
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Container(
            padding: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: errorText != null ? const Color(0xFFEF4444) : _primaryGreen, 
                  width: 1.0
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPrefixIcon(icon: icon, assetPath: prefixAssetPath),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF858991),
                          fontSize: 14,
                        ),
                      ),
                      TextFormField(
                        controller: TextEditingController(text: value),
                        readOnly: true,
                        style: TextStyle(
                          color: value.isEmpty
                              ? const Color(0xFF9CA3AF)
                              : _textColor,
                          fontSize: 15,
                          fontWeight: value.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          border: InputBorder.none,
                          hintText: label,
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showChevron)
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF111827),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 44),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ),
      ],
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
    bool readOnly = false,
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
        Container(
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: errorText != null ? const Color(0xFFEF4444) : _primaryGreen, 
                width: 1.0
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPrefixIcon(icon: icon, assetPath: prefixAssetPath),
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
                      keyboardType: keyboardType,
                      inputFormatters: isNumericKeyboard
                          ? [FilteringTextInputFormatter.deny(RegExp(r'-'))]
                          : null,
                      minLines: minLines,
                      maxLines: maxLines,
                      onChanged: onChanged,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                      readOnly: readOnly,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        hintText: hint,
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 44),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrefixIcon({IconData? icon, String? assetPath}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: assetPath != null
          ? (assetPath.endsWith('.svg')
                ? SvgPicture.asset(
                    assetPath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    assetPath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ))
          : Icon(icon ?? Icons.circle_outlined, color: _primaryGreen, size: 32),
    );
  }
}
