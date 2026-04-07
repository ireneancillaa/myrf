import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';

class DietPenMappingSection extends StatelessWidget {
  const DietPenMappingSection({super.key, required this.controller});

  final BroilerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final replication = controller.dietReplication.value ?? 0;

      if (replication <= 0) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Text(
            'Pilih Diet/Replication pada Project Information terlebih dahulu.',
            style: TextStyle(
              fontSize: 14,
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
            replication,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == replication - 1 ? 0 : 20,
              ),
              child: _DietCard(
                controller: controller,
                dietNumber: index + 1,
                replication: replication,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _DietCard extends StatefulWidget {
  const _DietCard({
    required this.controller,
    required this.dietNumber,
    required this.replication,
  });

  final BroilerController controller;

  final int dietNumber;
  final int replication;

  @override
  State<_DietCard> createState() => _DietCardState();
}

class _DietCardState extends State<_DietCard> {
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

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: const Color(0xFFF2F2EC),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Pens',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Scrollbar(
                          child: ListView.separated(
                            itemCount: 42,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final penNumber = index + 1;
                              final isSelected = tempSelectedPens.contains(
                                penNumber,
                              );
                              final isUsedByOtherDiet =
                                  usedPens.contains(penNumber) && !isSelected;

                              return InkWell(
                                onTap: isUsedByOtherDiet
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          if (isSelected) {
                                            tempSelectedPens.remove(penNumber);
                                          } else {
                                            tempSelectedPens.add(penNumber);
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
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
                                                fontSize: 20,
                                                fontWeight: FontWeight.w400,
                                                color: isUsedByOtherDiet
                                                    ? const Color(0xFFB6B6B6)
                                                    : const Color(0xFF1D1D1D),
                                              ),
                                            ),
                                            if (isUsedByOtherDiet) ...[
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Used by another diet',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFFE15757),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
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
                                        activeColor: const Color(0xFF1D8F47),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D8F47),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop(tempSelectedPens.toList()..sort());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D8F47),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const Spacer(),
              Text(
                'Replication : ${widget.replication}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _DietInputField(label: 'Pre Starter (0-10 days)'),
          const SizedBox(height: 10),
          const _DietInputField(label: 'Starter (11-21 days)'),
          const SizedBox(height: 10),
          const _DietInputField(label: 'Finisher (22-45 days)'),
          const SizedBox(height: 10),
          const _DietInputField(
            label: 'Remarks',
            icon: Icons.insert_drive_file,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE0E0E0), height: 1),
          const SizedBox(height: 14),
          const Text(
            'Pen Mapping',
            style: TextStyle(
              fontSize: 20,
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
                              fontSize: 15,
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _selectPens,
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF22C55E)),
            label: const Text(
              'Select Pens',
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFF22C55E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    this.icon = Icons.info,
    this.maxLines = 1,
  });

  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF444444)),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF22C55E)),
        ),
      ),
    );
  }
}
