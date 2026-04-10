import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../models/broiler_project_data.dart';

class InfeedPage extends StatefulWidget {
  const InfeedPage({super.key});

  @override
  State<InfeedPage> createState() => _InfeedPageState();
}

class _InfeedPageState extends State<InfeedPage>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF111827);
  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  late final TabController _tabController;
  late final BroilerController _controller;

  final _formKeys = List.generate(8, (_) => GlobalKey<FormState>());
  final _dateControllers = List.generate(8, (_) => TextEditingController());
  final _feedUsedControllers = List.generate(8, (_) => TextEditingController());
  final _selectedPens = List<String?>.filled(8, null);
  final _selectedDiets = List<String?>.filled(8, null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _dateControllers) {
      controller.dispose();
    }
    for (final controller in _feedUsedControllers) {
      controller.dispose();
    }
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

  Future<void> _selectDate(int formIndex) async {
    final currentText = _dateControllers[formIndex].text.trim();
    final initialDate = _parseInitialDate(currentText);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      _dateControllers[formIndex].text = _formatDate(date);
    }
  }

  DateTime _parseInitialDate(String value) {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);

    if (value.isEmpty) {
      return currentDate;
    }

    final parts = value.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[2]) ?? currentDate.year,
        int.tryParse(parts[1]) ?? currentDate.month,
        int.tryParse(parts[0]) ?? currentDate.day,
      );
    }

    return currentDate;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _submit(int formIndex, String stageName) {
    final formState = _formKeys[formIndex].currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Infeed data saved for $stageName'),
        backgroundColor: _primaryGreen,
      ),
    );

    _dateControllers[formIndex].clear();
    _feedUsedControllers[formIndex].clear();
  }

  String _getStageName(int stageIndex) {
    switch (stageIndex) {
      case 0:
        return 'Pre Starter (0-10 days)';
      case 1:
      case 2:
      case 3:
        return 'Starter (11-21 days)';
      default:
        return 'Finisher (22-45 days)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Infeed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.75),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pre Starter'),
            Tab(text: 'Starter'),
            Tab(text: 'Finisher'),
          ],
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPreStarterForm(project),
              _buildStarterForm(project),
              _buildFinisherForm(project),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPreStarterForm(BroilerProjectData project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(project),
          const SizedBox(height: 24),
          const Text(
            'Pre Starter (0-10 days)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 0,
            stageName: _getStageName(0),
            formNumber: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStarterForm(BroilerProjectData project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(project),
          const SizedBox(height: 24),
          const Text(
            'Starter (11-21 days)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 1,
            stageName: _getStageName(1),
            formNumber: 1,
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 2,
            stageName: _getStageName(2),
            formNumber: 2,
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 3,
            stageName: _getStageName(3),
            formNumber: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildFinisherForm(BroilerProjectData project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(project),
          const SizedBox(height: 24),
          const Text(
            'Finisher (22-45 days)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 4,
            stageName: _getStageName(4),
            formNumber: 1,
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 5,
            stageName: _getStageName(5),
            formNumber: 2,
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 6,
            stageName: _getStageName(6),
            formNumber: 3,
          ),
          const SizedBox(height: 16),
          _buildFeedForm(
            formIndex: 7,
            stageName: _getStageName(7),
            formNumber: 4,
          ),
        ],
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

  Widget _buildFeedForm({
    required int formIndex,
    required String stageName,
    required int formNumber,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKeys[formIndex],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Form $formNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Pen Number',
                icon: Icons.tag,
                value: _selectedPens[formIndex],
                items: List.generate(10, (index) {
                  final formattedPen =
                      'Pen ${(index + 1).toString().padLeft(2, '0')}';
                  return DropdownMenuItem(
                    value: formattedPen,
                    child: Text(formattedPen),
                  );
                }),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPens[formIndex] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Diet',
                icon: Icons.lunch_dining,
                value: _selectedDiets[formIndex],
                items: const [
                  DropdownMenuItem(value: 'Diet A', child: Text('Diet A')),
                  DropdownMenuItem(value: 'Diet B', child: Text('Diet B')),
                  DropdownMenuItem(value: 'Diet C', child: Text('Diet C')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedDiets[formIndex] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDateField(
                controller: _dateControllers[formIndex],
                onTap: () => _selectDate(formIndex),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _feedUsedControllers[formIndex],
                label: 'Feed Used (kg)',
                icon: Icons.lunch_dining,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validatorMessage: 'Please enter feed used',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submit(formIndex, stageName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save $stageName',
                    style: const TextStyle(
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: _fieldTextSize,
          color: _textPrimary,
          height: 1.0,
        ),
        decoration: _fieldDecoration(label: label, hint: label, icon: icon)
            .copyWith(
              labelText: label == 'Pen Number' && value == null ? null : label,
            ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        readOnly: true,
        controller: controller,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(
          label: 'Date',
          hint: 'Date',
          icon: Icons.calendar_today,
        ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
        onTap: onTap,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select a date';
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
