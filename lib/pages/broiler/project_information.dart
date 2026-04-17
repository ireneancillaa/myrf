import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';

// TODO: kalau ada nama yg sama dgn status drafted maka akan muncul pop up, kalau statusnya in progress maka bisa sama projectnya
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
              context: context,
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
              context: context,
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
                    label: 'Weighing 3 Weeks (kg)',
                    hint: 'Weighing 3 Weeks',
                    icon: Icons.looks_3,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: controller.weighing5WeeksController,
                    label: 'Weighing 5 Weeks (kg)',
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
              hint: 'DOC Weight',
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
              context: context,
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
        _buildFieldLabel(label, isMandatory: isMandatory),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _fieldHeight),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: isNumericKeyboard
                ? [FilteringTextInputFormatter.deny(RegExp(r'-'))]
                : null,
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
    required BuildContext context,
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

      final optionValues = items
          .map((item) => item.value?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();

      final selectedValue = hasSelectedValue ? rawSelectedValue : null;

      Widget? mandatoryHintWidget;
      if (showMandatoryInHint && isMandatory && selectedValue == null) {
        mandatoryHintWidget = Transform.translate(
          // Shift slightly upward (negative Y offset) to compensate for the dropdown baseline
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
            child: FormField<String>(
              initialValue: selectedValue,
              validator: isMandatory
                  ? (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return '$label is required';
                      }
                      return null;
                    }
                  : null,
              builder: (fieldState) {
                return InkWell(
                  onTap: () async {
                    final picked = await _showDropdownBottomSheet(
                      context: context,
                      title: label,
                      hint: hint,
                      options: optionValues,
                      selectedValue: selectedValue,
                    );

                    if (picked == null) return;

                    fieldState.didChange(picked);
                    onChanged(picked);
                  },
                  borderRadius: BorderRadius.circular(6),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  overlayColor: WidgetStatePropertyAll(Colors.transparent),
                  child: InputDecorator(
                    isEmpty: selectedValue == null,
                    decoration:
                        _fieldDecoration(
                          hint: hint,
                          icon: icon,
                          isMandatory: isMandatory,
                          hintWidget: mandatoryHintWidget,
                        ).copyWith(
                          errorText: fieldState.errorText,
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
                    child: Text(
                      selectedValue ?? '',
                      style: TextStyle(
                        fontSize: _fieldTextSize,
                        color: selectedValue == null
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Future<String?> _showDropdownBottomSheet({
    required BuildContext context,
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
                            overlayColor: WidgetStatePropertyAll(
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
