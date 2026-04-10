import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/diet_mapping_controller.dart';

class DietPenMappingSection extends StatelessWidget {
  const DietPenMappingSection({super.key, required this.controller});

  static const double _fieldTextSize = 14;
  static const double _fieldHintSize = 14;
  static const double _fieldHeight = 50;

  final DietMappingController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Obx(() {
        final diet = controller.dietCount.value ?? 0;
        final replication = controller.dietReplication.value ?? 0;

        if (diet <= 0 || replication <= 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Text(
              'Select Diet and Replication in Project Information first.',
              style: TextStyle(
                fontSize: _fieldTextSize,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diet Configuration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              diet,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index == diet - 1 ? 0 : 20),
                child: _DietCard(
                  controller: controller,
                  dietNumber: index + 1,
                  replication: replication,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DietCard extends StatefulWidget {
  const _DietCard({
    required this.controller,
    required this.dietNumber,
    required this.replication,
  });

  final DietMappingController controller;

  final int dietNumber;
  final int replication;

  @override
  State<_DietCard> createState() => _DietCardState();
}

class _DietCardState extends State<_DietCard> {
  static const double _selectPensDialogRadius = 28;
  static const double _selectPensButtonRadius = 14;

  Future<void> _selectPens() async {
    final selectedPens = widget.controller
        .dietPensFor(widget.dietNumber)
        .toSet();

    final result = await showDialog<List<int>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final tempSelectedPens = <int>{...selectedPens};

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final usedPens = widget.controller.usedPensExcept(
              widget.dietNumber,
            );
            final availablePens = List<int>.generate(
              42,
              (index) => index + 1,
            ).where((penNumber) => !usedPens.contains(penNumber)).toList();
            final allAvailableSelected =
                availablePens.isNotEmpty &&
                availablePens.every(tempSelectedPens.contains);

            void toggleSelectAll() {
              setDialogState(() {
                if (allAvailableSelected) {
                  tempSelectedPens.removeAll(availablePens);
                } else {
                  tempSelectedPens.addAll(availablePens);
                }
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_selectPensDialogRadius),
              ),
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 680),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _selectPensDialogRadius,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFF8FAF4),
                                const Color(0xFFFFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F6ED),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.view_week_rounded,
                                  color: Color(0xFF1D8F47),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Pens',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Select pens for this diet and save changes.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${tempSelectedPens.length}/42 selected',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Scrollbar(
                              child: ListView.separated(
                                itemCount: 42,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final penNumber = index + 1;
                                  final isSelected = tempSelectedPens.contains(
                                    penNumber,
                                  );
                                  final isUsedByOtherDiet =
                                      usedPens.contains(penNumber) &&
                                      !isSelected;

                                  final cardColor = isSelected
                                      ? const Color(0xFFE8F6ED)
                                      : Colors.white;

                                  return InkWell(
                                    onTap: isUsedByOtherDiet
                                        ? null
                                        : () {
                                            setDialogState(() {
                                              if (isSelected) {
                                                tempSelectedPens.remove(
                                                  penNumber,
                                                );
                                              } else {
                                                tempSelectedPens.add(penNumber);
                                              }
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(18),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF1D8F47)
                                              : isUsedByOtherDiet
                                              ? const Color(0xFFF2B4B4)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              isSelected ? 0.06 : 0.03,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pen $penNumber',
                                                  style: TextStyle(
                                                    fontSize:
                                                        DietPenMappingSection
                                                            ._fieldTextSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: isUsedByOtherDiet
                                                        ? const Color(
                                                            0xFFB6B6B6,
                                                          )
                                                        : const Color(
                                                            0xFF1D1D1D,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  isUsedByOtherDiet
                                                      ? 'Used by another diet'
                                                      : isSelected
                                                      ? 'Selected for diet ${widget.dietNumber}'
                                                      : 'Tap to select this pen',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isUsedByOtherDiet
                                                        ? const Color(
                                                            0xFFE15757,
                                                          )
                                                        : isSelected
                                                        ? const Color(
                                                            0xFF1D8F47,
                                                          )
                                                        : const Color(
                                                            0xFF6B7280,
                                                          ),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: isUsedByOtherDiet
                                                ? null
                                                : (value) {
                                                    setDialogState(() {
                                                      if (value == true) {
                                                        tempSelectedPens.add(
                                                          penNumber,
                                                        );
                                                      } else {
                                                        tempSelectedPens.remove(
                                                          penNumber,
                                                        );
                                                      }
                                                    });
                                                  },
                                            activeColor: const Color(
                                              0xFF1D8F47,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: availablePens.isEmpty
                                      ? null
                                      : toggleSelectAll,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1D8F47),
                                    side: const BorderSide(
                                      color: Color(0xFF1D8F47),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _selectPensButtonRadius,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    allAvailableSelected
                                        ? 'Clear All'
                                        : 'Select All',
                                    style: const TextStyle(
                                      fontSize:
                                          DietPenMappingSection._fieldTextSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1D8F47),
                                    side: const BorderSide(
                                      color: Color(0xFF1D8F47),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _selectPensButtonRadius,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize:
                                          DietPenMappingSection._fieldTextSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(tempSelectedPens.toList()..sort());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D8F47),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _selectPensButtonRadius,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize:
                                          DietPenMappingSection._fieldTextSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      widget.controller.updateDietPens(widget.dietNumber, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Diet ${widget.dietNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const Spacer(),
              Text(
                'Replication : ${widget.replication}',
                style: const TextStyle(
                  fontSize: DietPenMappingSection._fieldTextSize,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DietInputField(
            label: 'Pre Starter (0-10 days)',
            value: widget.controller.dietInputFor(
              widget.dietNumber,
              'preStarter',
            ),
            onChanged: (value) {
              widget.controller.updateDietInput(
                widget.dietNumber,
                'preStarter',
                value,
              );
            },
          ),
          const SizedBox(height: 10),
          _DietInputField(
            label: 'Starter (11-21 days)',
            value: widget.controller.dietInputFor(widget.dietNumber, 'starter'),
            onChanged: (value) {
              widget.controller.updateDietInput(
                widget.dietNumber,
                'starter',
                value,
              );
            },
          ),
          const SizedBox(height: 10),
          _DietInputField(
            label: 'Finisher (22-45 days)',
            value: widget.controller.dietInputFor(
              widget.dietNumber,
              'finisher',
            ),
            onChanged: (value) {
              widget.controller.updateDietInput(
                widget.dietNumber,
                'finisher',
                value,
              );
            },
          ),
          const SizedBox(height: 10),
          _DietInputField(
            label: 'Remarks (Optional)',
            icon: Icons.insert_drive_file,
            maxLines: 2,
            value: widget.controller.dietInputFor(widget.dietNumber, 'remarks'),
            onChanged: (value) {
              widget.controller.updateDietInput(
                widget.dietNumber,
                'remarks',
                value,
              );
            },
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE0E0E0), height: 1),
          const SizedBox(height: 14),
          const Text(
            'Pen Mapping',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final selectedPens = widget.controller.dietPensFor(
              widget.dietNumber,
            );

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedPens
                  .map(
                    (penNumber) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDADADA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pen $penNumber',
                            style: const TextStyle(
                              fontSize: DietPenMappingSection._fieldTextSize,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final updatedPens = List<int>.from(selectedPens)
                                ..remove(penNumber);
                              widget.controller.updateDietPens(
                                widget.dietNumber,
                                updatedPens,
                              );
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
          const SizedBox(height: 5),
          OutlinedButton.icon(
            onPressed: _selectPens,
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF22C55E)),
            label: const Text(
              'Select Pens',
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontSize: DietPenMappingSection._fieldTextSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFF22C55E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietInputField extends StatelessWidget {
  const _DietInputField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.info,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: DietPenMappingSection._fieldTextSize),
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        hintStyle: const TextStyle(
          fontSize: DietPenMappingSection._fieldHintSize,
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
          borderSide: BorderSide(color: Color(0xFF22C55E)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );

    if (maxLines == 1) {
      return SizedBox(height: DietPenMappingSection._fieldHeight, child: field);
    }

    return field;
  }
}
