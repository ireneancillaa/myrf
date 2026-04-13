import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';

class DepletionPage extends StatefulWidget {
  const DepletionPage({super.key});

  @override
  State<DepletionPage> createState() => _DepletionPageState();
}

class _DepletionPageState extends State<DepletionPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);
  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _mortalityCullController = TextEditingController();
  final _bodyWeightController = TextEditingController();
  final _remarksController = TextEditingController();

  late final BroilerController _controller;

  String? _selectedPen;
  int _age = 0;

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
    _mortalityCullController.dispose();
    _bodyWeightController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  BroilerProjectData? _currentProject() {
    final selectedName = _controller.selectedProjectName.value;
    if (selectedName == null || selectedName.trim().isEmpty) {
      return null;
    }

    for (final project in _controller.projects) {
      if (project.projectName == selectedName) {
        return project;
      }
    }

    return null;
  }

  Future<void> _selectDate() async {
    final currentText = _dateController.text.trim();
    final initialDate = _parseDate(currentText) ?? _todayDate();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date == null) return;

    final selectedDate = DateTime(date.year, date.month, date.day);
    _dateController.text = _formatDate(selectedDate);

    final project = _currentProject();
    final docInDate = _parseDate(project?.docInDate ?? '');
    if (docInDate == null) {
      setState(() {
        _age = 0;
      });
      return;
    }

    final daysDifference = selectedDate.difference(docInDate).inDays;
    setState(() {
      _age = daysDifference.clamp(0, 60);
    });
  }

  DateTime _todayDate() {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Depletion data saved successfully'),
        backgroundColor: _primaryGreen,
      ),
    );
    Navigator.of(context).pop();
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
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Text(
          'Depletion',
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
        child: Obx(() {
          final project = _currentProject();
          if (project == null) {
            return const Center(child: Text('Please select a project first'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(project),
                  const SizedBox(height: 24),
                  const Text(
                    'Record Mortality/Cull',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: 'Age',
                    icon: Icons.timer,
                    value: _age > 0 ? '$_age days' : '',
                  ),
                  const SizedBox(height: 16),
                  _buildPenDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _mortalityCullController,
                    label: 'Mortality / Cull',
                    icon: Icons.warning_amber,
                    validatorMessage: 'Please enter mortality/cull count',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bodyWeightController,
                    label: 'Body Weight (kg)',
                    icon: Icons.scale,
                    validatorMessage: 'Please enter body weight',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: _fieldTextSize),
                    decoration: _fieldDecoration(
                      label: 'Remarks',
                      hint: 'Remarks',
                      icon: Icons.note,
                    ).copyWith(alignLabelWithHint: false),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Data',
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
          );
        }),
      ),
    );
  }

  Widget _buildInfoCard(BroilerProjectData project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.projectName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              project.trialHouse,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(
          label: 'Date',
          hint: 'Date',
          icon: Icons.calendar_today,
        ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
        onTap: _selectDate,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(label: label, hint: label, icon: icon),
      ),
    );
  }

  Widget _buildPenDropdown() {
    return SizedBox(
      height: _fieldHeight,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPen,
        isExpanded: true,
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: _fieldTextSize,
          color: _textPrimary,
          height: 1.0,
        ),
        decoration: _fieldDecoration(
          label: 'Pen Number',
          hint: 'Pen Number',
          icon: Icons.tag,
        ).copyWith(labelText: _selectedPen == null ? null : 'Pen Number'),
        items: List.generate(20, (index) {
          final formattedPen = 'Pen ${(index + 1).toString().padLeft(2, '0')}';
          return DropdownMenuItem(
            value: formattedPen,
            child: Text(formattedPen),
          );
        }),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedPen = value;
          });
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorMessage,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(label: label, hint: label, icon: icon),
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
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      hintStyle: const TextStyle(
        fontSize: _fieldHintSize,
        color: Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryGreen),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
