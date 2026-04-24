import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/broiler_controller.dart';
import '../../controller/male_birds_controller.dart';
import 'male_birds_calculator_page.dart';

class MaleBirdsInputPage extends StatefulWidget {
  const MaleBirdsInputPage({super.key});

  @override
  State<MaleBirdsInputPage> createState() => _MaleBirdsInputPageState();
}

class _MaleBirdsInputPageState extends State<MaleBirdsInputPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);

  late final BroilerController _broilerController;
  late final MaleBirdsController _maleBirdsController;

  DateTime _selectedDate = DateTime.now();
  List<double> _maleValues = [];
  List<double> _femaleValues = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _broilerController = Get.find<BroilerController>();
    _maleBirdsController = Get.isRegistered<MaleBirdsController>()
        ? Get.find<MaleBirdsController>()
        : Get.put(MaleBirdsController());
  }

  double get _totalMaleWeight => _maleValues.fold(0, (sum, val) => sum + val);

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: _textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _primaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _onMaleTap() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MaleBirdsCalculatorPage(
          stageTitle: 'Male Birds',
          stageGroup: 'Weight',
          stageRange: '-',
          initialDate: _formatDate(_selectedDate),
          initialValues: _maleValues,
        ),
      ),
    );

    if (result != null && result['values'] is List) {
      setState(() {
        _maleValues = (result['values'] as List).cast<double>();
      });
    }
  }

  String _formatTotal(double total) {
    if (total == 0) return '-';
    if (total % 1 == 0) return total.toInt().toString();
    return total.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (_maleValues.isEmpty && _femaleValues.isEmpty) {
      Get.snackbar(
        'Error',
        'Please input at least one bird weight',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Logic for Female bird calculation
      int numberOfBirds = 0;
      final projectName = _broilerController.selectedProjectName.value;
      for (final project in _broilerController.projects) {
        if (project.projectName == projectName) {
          numberOfBirds = int.tryParse(project.numberOfBirds) ?? 0;
        }
      }

      int currentTotalMale = 0;
      for (final e in _maleBirdsController.entries) {
        currentTotalMale += int.tryParse(e.male) ?? 0;
      }
      final newMaleValue = _totalMaleWeight.toInt();
      // Female = Total - (Previous Male + New Male)
      final calculatedFemale =
          numberOfBirds - (currentTotalMale + newMaleValue);

      final entry = MaleBirdsEntry(
        date: _formatDate(_selectedDate),
        age: _calculatedAge.toString(),
        male: _totalMaleWeight > 0 ? _formatTotal(_totalMaleWeight) : '-',
        female: calculatedFemale.toString(),
        recordedAt: DateTime.now(),
      );

      await _maleBirdsController.addMaleBirds(entry);

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save data: $e',
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFFB91C1C),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _calculatedAge {
    final docInStr = _broilerController.docInDateController.text;
    if (docInStr.isEmpty) return 1;
    try {
      final docInParts = docInStr.split('/');
      if (docInParts.length == 3) {
        final docInDate = DateTime(
          int.parse(docInParts[2]),
          int.parse(docInParts[1]),
          int.parse(docInParts[0]),
        );
        final d1 = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        final d2 = DateTime(docInDate.year, docInDate.month, docInDate.day);
        final age = d1.difference(d2).inDays + 1;
        return age > 0 ? age : 1;
      }
    } catch (_) {}
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New Male Birds',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Expanded(
                    child: _buildUnderlineField(
                      icon: Icons.calendar_month,
                      label: 'Date',
                      hintText: 'Date',
                      controller: TextEditingController(
                        text: _formatDate(_selectedDate),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Age
                  Expanded(
                    child: _buildUnderlineField(
                      icon: Icons.pets,
                      prefixAssetPath: 'assets/age.png',
                      label: 'Age',
                      hintText: 'Age',
                      controller: TextEditingController(
                        text: '$_calculatedAge',
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Birds Weight Section
              _buildSectionTitle('Male Birds Quantity'),
              const SizedBox(height: 16),

              // Male Card
              _buildChecklistItem(
                title: 'Male Birds',
                value: _totalMaleWeight > 0
                    ? _formatTotal(_totalMaleWeight)
                    : null,
                unit: '',
                onTap: _onMaleTap,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Male Birds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
            bottom: BorderSide(
              color: Color(0xFF22C55E),
              width: 0.8,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
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
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
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
}
