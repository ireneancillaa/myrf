import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';

class BroilerProjectInformationSection extends StatelessWidget {
  const BroilerProjectInformationSection({
    super.key,
    required this.controller,
    required this.formKey,
    this.showValidation = false,
  });

  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final BroilerController controller;
  final GlobalKey<FormState> formKey;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: formKey,
        autovalidateMode: showValidation
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
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

            // 1. Project Name / Chick Cycle (string, freetext, mandatory)
            _buildTextField(
              controller: controller.projectNameController,
              label: 'Project Name / Chick Cycle',
              hint: 'Project Name / Chick Cycle',
              icon: Icons.autorenew_rounded,
              isMandatory: true,
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // 2. Strain (string, dropdown)
            _buildStringDropdownField(
              valueListenable: controller.selectedStrain,
              label: 'Strain',
              hint: 'Select Strain',
              icon: Icons.category_outlined,
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

            // 3. Hatchery (string, dropdown)
            _buildStringDropdownField(
              valueListenable: controller.selectedHatchery,
              label: 'Hatchery',
              hint: 'Select Hatchery',
              icon: Icons.egg_alt_outlined,
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

            // 4. Breeding Farm (string, freetext)
            _buildTextField(
              controller: controller.breedingFarmController,
              label: 'Breeding Farm',
              hint: 'Breeding Farm',
              icon: Icons.house_outlined,
            ),
            const SizedBox(height: 16),

            // 5. Box Code (string, freetext)
            _buildTextField(
              controller: controller.boxBatchCodeController,
              label: 'Box Code',
              hint: 'Box Code',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 16),

            // 6. Selector (string, freetext)
            _buildTextField(
              controller: controller.selectorController,
              label: 'Selector',
              hint: 'Selector',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // 7. Date Trial (date picker, mandatory)
            _buildDateField(
              context,
              label: 'Date Trial',
              controller: controller.trialDateController,
              icon: Icons.calendar_today,
              isMandatory: true,
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _initialDate(
                    controller.trialDateController.text,
                  ),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (selected != null) {
                  controller.trialDateController.text = _formatDate(selected);
                }
              },
            ),
            const SizedBox(height: 16),

            // 8 & 9. Weighing 3 Weeks + Weighing 5 Weeks (single line)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.weighing3WeeksController,
                    label: 'Weighing 3 Weeks',
                    hint: 'Weighing 3 Weeks',
                    icon: Icons.looks_3,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: controller.weighing5WeeksController,
                    label: 'Weighing 5 Weeks',
                    hint: 'Weighing 5 Weeks',
                    icon: Icons.looks_5,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 10. Number of Birds (integer)
            _buildTextField(
              controller: controller.numberOfBirdsController,
              label: 'Number of Birds',
              hint: 'Number of Birds',
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 11. DOC Weight (Kg) (double, mandatory)
            _buildTextField(
              controller: controller.docWeightController,
              label: 'DOC Weight (Kg)',
              hint: 'DOC Weight (Kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              isMandatory: true,
            ),
            const SizedBox(height: 16),

            // 12. DOC In (date picker, mandatory)
            _buildDateField(
              context,
              label: 'DOC In',
              controller: controller.docInDateController,
              icon: Icons.calendar_today,
              isMandatory: true,
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _initialDate(
                    controller.docInDateController.text,
                  ),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (selected != null) {
                  controller.docInDateController.text = _formatDate(selected);
                }
              },
            ),
            const SizedBox(height: 16),

            // 13. Map of Trial House (dropdown, mandatory)
            _buildStringDropdownField(
              valueListenable: controller.selectedTrialHouse,
              label: 'Map of Trial House',
              hint: 'Map of Trial House',
              icon: Icons.map_outlined,
              isMandatory: true,
              showMandatoryInHint: false,
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: '${index + 1}A',
                  child: Text('${index + 1}A'),
                ),
              ),
              onChanged: (value) {
                controller.selectedTrialHouse.value = value;
                controller.trialHouseController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),

            // 14 & 15. Diet + Replication (single line)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.dietController,
                    label: 'Diet',
                    hint: 'Diet',
                    icon: Icons.local_dining,
                    keyboardType: TextInputType.number,
                    isMandatory: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: controller.replicationController,
                    label: 'Replication',
                    hint: 'Replication',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number,
                    isMandatory: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    bool isMandatory = false,
    Widget? hintWidget,
  }) {
    return InputDecoration(
      isDense: true,
      hint: hintWidget,
      hintText: hintWidget == null ? hint : null,
      hintStyle: const TextStyle(
        fontSize: _fieldHintSize,
        color: Color(0xFF9CA3AF),
        height: 1.0,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 0, right: 8),
        child: Icon(icon),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF22C55E), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildFieldLabel(String label, {bool isMandatory = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        children: isMandatory
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : const [],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isMandatory = false,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isMandatory: isMandatory),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _fieldHeight),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            style: const TextStyle(fontSize: _fieldTextSize),
            validator: isMandatory
                ? (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
            decoration: _fieldDecoration(
              hint: hint,
              icon: icon,
              isMandatory: isMandatory,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStringDropdownField({
    required RxnString valueListenable,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool isMandatory = false,
    bool showMandatoryInHint = false,
  }) {
    return Obx(() {
      final rawSelectedValue = valueListenable.value?.trim() ?? '';
      final hasSelectedValue = rawSelectedValue.isNotEmpty;

      final baseItems = List<DropdownMenuItem<String>>.from(items);
      final hasMatchingItem = baseItems.any(
        (item) => item.value == rawSelectedValue,
      );

      if (hasSelectedValue && !hasMatchingItem) {
        baseItems.insert(
          0,
          DropdownMenuItem<String>(
            value: rawSelectedValue,
            child: Text(rawSelectedValue),
          ),
        );
      }

      final selectedValue = hasSelectedValue ? rawSelectedValue : null;

      Widget? mandatoryHintWidget;
      if (showMandatoryInHint && isMandatory && selectedValue == null) {
        mandatoryHintWidget = Transform.translate(
          // Geser sedikit ke atas (offset negatif Y) untuk kompensasi dropdown baseline
          offset: const Offset(0, -4),
          child: Text.rich(
            TextSpan(
              text: hint,
              style: const TextStyle(
                fontSize: _fieldHintSize,
                color: Color(0xFF6B7280),
                height:
                    1.0, // Keep line-height at 1.0 to avoid extra vertical space
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label, isMandatory: isMandatory),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _fieldHeight),
            child: DropdownButtonFormField<String>(
              initialValue: selectedValue,
              isExpanded: true,
              isDense: true,
              dropdownColor: Colors.white,
              hint: Text(
                hint,
                style: const TextStyle(
                  fontSize: _fieldHintSize,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: Color(0xFF6B7280),
              ),
              alignment: Alignment.centerLeft,
              style: const TextStyle(
                fontSize: _fieldTextSize,
                color: Color(0xFF111827),
                height: 1.0,
              ),
              decoration: _fieldDecoration(
                hint: hint,
                icon: icon,
                isMandatory: isMandatory,
                hintWidget: mandatoryHintWidget,
              ),
              validator: isMandatory
                  ? (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return '$label is required';
                      }
                      return null;
                    }
                  : null,
              items: baseItems,
              onChanged: onChanged,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
    bool isMandatory = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isMandatory: isMandatory),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _fieldHeight),
          child: TextFormField(
            readOnly: true,
            controller: controller,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontSize: _fieldTextSize,
              color: Color(0xFF111827),
              height: 1.0,
            ),
            decoration:
                _fieldDecoration(
                  hint: label,
                  icon: icon,
                  isMandatory: isMandatory,
                ).copyWith(
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Color(0xFF6B7280),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
            validator: isMandatory
                ? (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
            onTap: onTap,
          ),
        ),
      ],
    );
  }

  DateTime _initialDate(String value) {
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
}
