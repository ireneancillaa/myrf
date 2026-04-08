import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';

class BroilerProjectInformationSection extends StatelessWidget {
  const BroilerProjectInformationSection({super.key, required this.controller});

  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final BroilerController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.projectNameController,
              label: 'Project Name',
              hint: 'Project Name',
              icon: Icons.folder,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              context,
              label: 'Trial Date',
              controller: controller.trialDateController,
              icon: Icons.calendar_today,
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _initialDate(
                    controller.trialDateController.text,
                  ),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (selected != null) {
                  controller.trialDateController.text = _formatDate(selected);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildStringDropdownField(
              valueListenable: controller.selectedTrialHouse,
              label: 'Trial House',
              hint: 'Select Trial House',
              icon: Icons.home,
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: 'House ${index + 1}',
                  child: Text('House ${index + 1}'),
                ),
              ),
              onChanged: (value) {
                controller.selectedTrialHouse.value = value;
                controller.trialHouseController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            _buildStringDropdownField(
              valueListenable: controller.selectedStrain,
              label: 'Strain',
              hint: 'Select Strain',
              icon: Icons.biotech,
              items: const [
                DropdownMenuItem(value: 'Cobb 500', child: Text('Cobb 500')),
                DropdownMenuItem(value: 'Ross 308', child: Text('Ross 308')),
                DropdownMenuItem(value: 'Hubbard', child: Text('Hubbard')),
                DropdownMenuItem(value: 'Aviagen', child: Text('Aviagen')),
              ],
              onChanged: (value) {
                controller.selectedStrain.value = value;
                controller.strainController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            _buildStringDropdownField(
              valueListenable: controller.selectedHatchery,
              label: 'Hatchery',
              hint: 'Select Hatchery',
              icon: Icons.business,
              items: const [
                DropdownMenuItem(
                  value: 'Main Hatchery',
                  child: Text('Main Hatchery'),
                ),
                DropdownMenuItem(
                  value: 'North Hatchery',
                  child: Text('North Hatchery'),
                ),
                DropdownMenuItem(
                  value: 'South Hatchery',
                  child: Text('South Hatchery'),
                ),
              ],
              onChanged: (value) {
                controller.selectedHatchery.value = value;
                controller.hatcheryController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.breedingFarmController,
              label: 'Breeding Farm',
              hint: 'Breeding Farm',
              icon: Icons.agriculture,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.boxBatchCodeController,
              label: 'Box/Batch Code',
              hint: 'Box/Batch Code',
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.selectorController,
              label: 'Selector',
              hint: 'Selector',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              context,
              label: 'DOC In Date',
              controller: controller.docInDateController,
              icon: Icons.calendar_today,
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _initialDate(
                    controller.docInDateController.text,
                  ),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (selected != null) {
                  controller.docInDateController.text = _formatDate(selected);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.docWeightController,
              label: 'DOC Weight (kg)',
              hint: 'DOC Weight (kg)',
              icon: Icons.scale,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.weighing3WeeksController,
              label: 'Weighing 3 Weeks (g)',
              hint: 'Weighing 3 Weeks (g)',
              icon: Icons.monitor_weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.weighing5WeeksController,
              label: 'Weighing 5 Weeks (g)',
              hint: 'Weighing 5 Weeks (g)',
              icon: Icons.monitor_weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.numberOfBirdsController,
              label: 'Number of Birds',
              hint: 'Number of Birds',
              icon: Icons.people,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildIntDropdownField(
              valueListenable: controller.dietReplication,
              label: 'Diet/Replication',
              hint: 'Select Replication',
              icon: Icons.repeat,
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 Replications')),
                DropdownMenuItem(value: 3, child: Text('3 Replications')),
                DropdownMenuItem(value: 4, child: Text('4 Replications')),
                DropdownMenuItem(value: 5, child: Text('5 Replications')),
                DropdownMenuItem(value: 6, child: Text('6 Replications')),
                DropdownMenuItem(value: 7, child: Text('7 Replications')),
              ],
              onChanged: (value) {
                controller.dietReplication.value = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: _fieldHintSize,
        color: Color(0xFF9CA3AF),
      ),
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF22C55E)),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(label: label, hint: hint, icon: icon),
      ),
    );
  }

  Widget _buildStringDropdownField({
    required RxnString valueListenable,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Obx(() {
      final selectedValue = valueListenable.value;
      return SizedBox(
        height: _fieldHeight,
        child: DropdownButtonFormField<String>(
          initialValue: selectedValue,
          style: const TextStyle(
            fontSize: _fieldTextSize,
            color: Color(0xFF111827),
          ),
          dropdownColor: Colors.white,
          decoration: _fieldDecoration(
            label: selectedValue == null ? null : label,
            hint: hint,
            icon: icon,
          ),
          items: items,
          onChanged: onChanged,
        ),
      );
    });
  }

  Widget _buildIntDropdownField({
    required RxnInt valueListenable,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Obx(() {
      final selectedValue = valueListenable.value;
      return SizedBox(
        height: _fieldHeight,
        child: DropdownButtonFormField<int>(
          initialValue: selectedValue,
          style: const TextStyle(
            fontSize: _fieldTextSize,
            color: Color(0xFF111827),
          ),
          dropdownColor: Colors.white,
          decoration: _fieldDecoration(
            label: selectedValue == null ? null : label,
            hint: hint,
            icon: icon,
          ),
          items: items,
          onChanged: onChanged,
        ),
      );
    });
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: TextFormField(
        readOnly: true,
        controller: controller,
        style: const TextStyle(fontSize: _fieldTextSize),
        decoration: _fieldDecoration(
          label: label,
          hint: label,
          icon: icon,
        ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
        onTap: onTap,
      ),
    );
  }

  DateTime _initialDate(String value) {
    if (value.isEmpty) {
      return DateTime(2026, 7, 4);
    }

    final parts = value.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[2]) ?? 2026,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[0]) ?? 1,
      );
    }
    return DateTime(2026, 7, 4);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
