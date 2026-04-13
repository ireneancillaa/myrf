import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';

class FesesScorePage extends StatefulWidget {
  const FesesScorePage({super.key});

  @override
  State<FesesScorePage> createState() => _FesesScorePageState();
}

class _FesesScorePageState extends State<FesesScorePage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);
  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  late final BroilerController _controller;

  String? _selectedPen;
  int _selectedScore = 1;

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

    if (date != null) {
      final selectedDate = DateTime(date.year, date.month, date.day);
      _dateController.text = _formatDate(selectedDate);
    }
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
        content: Text('Feses score saved successfully'),
        backgroundColor: _primaryGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 1:
        return _primaryGreen;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _getScoreDescription(int score) {
    switch (score) {
      case 1:
        return 'Normal - Healthy droppings';
      case 2:
        return 'Slightly Abnormal - Monitor closely';
      case 3:
        return 'Abnormal - Check feed/water';
      case 4:
        return 'Very Abnormal - Immediate attention needed';
      default:
        return '';
    }
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
          'Feses Score',
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
                    'Record Feses Score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildPenDropdown(),
                  const SizedBox(height: 24),
                  const Text(
                    'Feses Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2,
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final score = index + 1;
                      final isSelected = _selectedScore == score;
                      final scoreColor = _getScoreColor(score);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedScore = score;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scoreColor
                                : scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? scoreColor
                                  : scoreColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Score $score',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : scoreColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getScoreDescription(score).split(' - ')[0],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : scoreColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getScoreColor(_selectedScore).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getScoreColor(_selectedScore).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _getScoreColor(_selectedScore),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getScoreDescription(_selectedScore),
                            style: TextStyle(
                              color: _getScoreColor(_selectedScore),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        'Save Score',
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
