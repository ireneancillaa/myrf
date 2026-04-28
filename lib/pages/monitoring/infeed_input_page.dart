import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/broiler_controller.dart';
import '../../controller/infeed_controller.dart';
import 'infeed_calculator_page.dart';

class InfeedInputPage extends StatefulWidget {
  const InfeedInputPage({super.key});

  @override
  State<InfeedInputPage> createState() => _InfeedInputPageState();
}

class _InfeedInputPageState extends State<InfeedInputPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);

  late final BroilerController _broilerController;
  late final InfeedController _infeedController;

  final List<String> _stages = ['Pre Starter', 'Starter', 'Finisher'];
  String _baseStageName = 'Pre Starter';
  int _selectedStageIndex = 0;
  String _selectedStageName = 'Pre Starter';
  DateTime _selectedDate = DateTime.now();
  List<double> _penValues = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _broilerController = Get.find<BroilerController>();
    _infeedController = Get.find<InfeedController>();

    // Initialize with first available slot
    _selectedStageIndex = _infeedController.getFirstEmptyIndex();
    if (_selectedStageIndex == -1) {
      // Handle all slots full case if necessary, for now use 0
      _selectedStageIndex = 0;
    }
  }

  void _updateStageInfo(String baseName) {
    setState(() {
      _baseStageName = baseName;
      _selectedStageName = baseName;
      // Index is already set in initState for new entries, 
      // or set when editing (if editing is implemented later)
      
      // Clear data for new entry section
      _penValues = [];
      _selectedDate = DateTime.now();
    });
  }

  // void _loadStageData(int index) {
  //   // This method is now less relevant for new numbered stages,
  //   // but we keep it for consistency if needed to load data from a slot.
  //   setState(() {
  //     _selectedStageIndex = index;
  //     if (index < _infeedController.stageNames.length) {
  //       _selectedStageName = _infeedController.stageNames[index];
  //     }
      
  //     final dateStr = _infeedController.dateControllers[index].text;
  //     if (dateStr.isNotEmpty) {
  //       try {
  //         _selectedDate = DateFormat('dd/MM/yyyy').parse(dateStr);
  //       } catch (e) {}
  //     }

  //     _penValues = List<double>.from(_infeedController.penValuesByStage[index]);
  //   });
  // }

  Future<void> _showStageSelection() async {
    const double optionRadius = 10.0;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Stage',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current: $_selectedStageName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _stages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final stage = _stages[index];
                        final isSelected = _baseStageName == stage;

                        return InkWell(
                          onTap: () => Navigator.pop(context, stage),
                          borderRadius: BorderRadius.circular(optionRadius),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEAF8EE)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(optionRadius),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stage,
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
        );
      },
    );

    if (picked != null) {
      _updateStageInfo(picked);
    }
  }

  double get _totalWeight => _penValues.fold(0, (sum, val) => sum + val);

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(yesterday)
          ? yesterday
          : (_selectedDate.isAfter(today) ? today : _selectedDate),
      firstDate: yesterday,
      lastDate: today,
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
        // 1. Update tanggal pilihan user
        _selectedDate = picked;

        // 2. Tentukan stage index: 0 (H-1), 1 (Hari ini)
        // final now = DateTime.now();
        _selectedDate = picked;
      });
    }
  }

  Future<void> _onChecklistTap() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => InfeedCalculatorPage(
          stageTitle: _selectedStageName,
          stageGroup: 'Infeed',
          stageRange: '-',
          initialDate: _formatDate(_selectedDate),
          initialValues: _penValues,
        ),
      ),
    );

    if (result != null && result['values'] is List) {
      setState(() {
        _penValues = (result['values'] as List).cast<double>();
      });
    }
  }

  String _formatTotal(double total) {
    if (total == 0) return '-';
    if (total % 1 == 0) return total.toInt().toString();
    return total.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (_penValues.isEmpty) {
      Get.snackbar(
        'Error',
        'Please input infeed weight first',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _infeedController.saveStage(
        stageIndex: _selectedStageIndex,
        stageName: _selectedStageName,
        dateStr: _formatDate(_selectedDate),
        values: _penValues,
      );

      Get.back();

      // Tampilkan snackbar SETELAH kembali ke halaman sebelumnya agar tidak ikut tertutup
      Get.snackbar(
        'Success',
        'Infeed data saved successfully',
        backgroundColor: const Color(0xFFDCFCE7),
        colorText: const Color(0xFF15803D),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      );
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
          'New Infeed',
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
              // TODO: dibikin jadi dropdown
              const SizedBox(height: 24),
              _buildUnderlineField(
                icon: Icons.person,
                label: 'Stages',
                hintText: 'Select Stage',
                controller: TextEditingController(text: _selectedStageName),
                readOnly: true,
                onTap: _showStageSelection,
              ),
              const SizedBox(height: 32),

              // Infeed Weight Section
              _buildSectionTitle('Infeed Weight'),
              const SizedBox(height: 16),

              // Infeed Card
              _buildChecklistItem(
                title: 'Infeed',
                value: _totalWeight > 0 ? _formatTotal(_totalWeight) : null,
                unit: 'kg',
                onTap: _onChecklistTap,
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
                      'Save Infeed',
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
