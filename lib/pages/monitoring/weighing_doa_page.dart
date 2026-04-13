import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';

class WeighingDoaPage extends StatefulWidget {
  const WeighingDoaPage({super.key, this.selectedFarmName});

  final String? selectedFarmName;

  @override
  State<WeighingDoaPage> createState() => _WeighingDoaPageState();
}

class _WeighingDoaPageState extends State<WeighingDoaPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);
  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _penNumberController = TextEditingController();
  final _boxWeightController = TextEditingController();
  final _feedUsedController = TextEditingController();
  final _lastTotalBirdsController = TextEditingController();
  final _actualTotalBirdsController = TextEditingController();
  final _totalWeightController = TextEditingController();

  late final BroilerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _penNumberController.dispose();
    _boxWeightController.dispose();
    _feedUsedController.dispose();
    _lastTotalBirdsController.dispose();
    _actualTotalBirdsController.dispose();
    _totalWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final initialDate = DateTime(today.year, today.month, today.day);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      _dateController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  String _contextName() {
    final selectedProject = _controller.selectedProjectName.value;
    final fromWidget = widget.selectedFarmName?.trim() ?? '';

    if (selectedProject != null && selectedProject.trim().isNotEmpty) {
      return selectedProject;
    }
    if (fromWidget.isNotEmpty) return fromWidget;
    return '';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weighing DOA data saved successfully'),
        backgroundColor: _primaryGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final contextName = _contextName();
    final hasContext = contextName.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'Weighing DOA',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: !hasContext
            ? const Center(child: Text('Please select a project first'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contextName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryGreen.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monitor_weight_outlined,
                              color: _primaryGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Isi data timbang harian untuk memantau performa dan angka mortalitas.',
                                style: TextStyle(
                                  color: _primaryGreen.withOpacity(0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Record Daily Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        controller: _dateController,
                        label: 'Date',
                        prefixIcon: Icons.calendar_today,
                        suffixIcon: Icons.arrow_drop_down,
                        readOnly: true,
                        onTap: _selectDate,
                        validatorMessage: 'Please select a date',
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _penNumberController,
                        label: 'Pen Number',
                        prefixIcon: Icons.tag_outlined,
                        validatorMessage: 'Please enter pen number',
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _boxWeightController,
                        label: 'Box Weight (kg)',
                        prefixIcon: Icons.scale_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validatorMessage: 'Please enter box weight',
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _feedUsedController,
                        label: 'Feed Used (kg)',
                        prefixIcon: Icons.soup_kitchen_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validatorMessage: 'Please enter feed used',
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _lastTotalBirdsController,
                        label: 'Last Total Birds',
                        prefixIcon: Icons.groups_2_outlined,
                        keyboardType: TextInputType.number,
                        validatorMessage: 'Please enter last total birds',
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _actualTotalBirdsController,
                        label: 'Actual Total Birds',
                        prefixIcon: Icons.group_outlined,
                        keyboardType: TextInputType.number,
                        validatorMessage: 'Please enter actual total birds',
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _totalWeightController,
                        label: 'Total Weight (kg)',
                        prefixIcon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validatorMessage: 'Please enter total weight',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Data',
                            style: TextStyle(
                              fontSize: 15,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required String validatorMessage,
    TextInputType? keyboardType,
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(
          label: label,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
        onTap: onTap,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return validatorMessage;
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      hintStyle: const TextStyle(
        fontSize: _fieldHintSize,
        color: Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF22C55E)),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}
