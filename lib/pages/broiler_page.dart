import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/broiler_controller.dart';
import '../controller/diet_mapping_controller.dart';
import '../controller/sample_doc_controller.dart';
import 'broiler/project_stepper_page.dart';

class BroilerPage extends StatefulWidget {
  const BroilerPage({super.key});

  @override
  State<BroilerPage> createState() => _BroilerPageState();
}

class _BroilerPageState extends State<BroilerPage> {
  late final BroilerController _controller;
  late final TextEditingController _searchController;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  _DateFilterOption? _selectedFilterOption;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        centerTitle: true,
        title: const Text(
          'Broiler Project List',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search project',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF6B7280),
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF22C55E),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _showDateFilterSheet(context);
                        },
                        icon: const Icon(Icons.filter_alt_outlined, size: 18),
                        label: Text(_dateFilterButtonLabel()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                          side: const BorderSide(color: Color(0xFF22C55E)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final keyword = _searchController.text.trim().toLowerCase();
                    final projects =
                        _controller.projects.where((item) {
                          final matchKeyword =
                              keyword.isEmpty ||
                              item.projectName.toLowerCase().contains(keyword);
                          final matchDate = _matchesDateFilter(item.trialDate);
                          return matchKeyword && matchDate;
                        }).toList()..sort((a, b) {
                          final aStatus = _controller.statusFor(a.projectName);
                          final bStatus = _controller.statusFor(b.projectName);
                          final aPriority =
                              aStatus == BroilerWorkflowStatus.drafted ? 0 : 1;
                          final bPriority =
                              bStatus == BroilerWorkflowStatus.drafted ? 0 : 1;

                          if (aPriority != bPriority) {
                            return aPriority.compareTo(bPriority);
                          }

                          final aTime = a.updatedAt ?? DateTime(1970);
                          final bTime = b.updatedAt ?? DateTime(1970);
                          return bTime.compareTo(aTime);
                        });
                    _controller.projectStatuses.toString();

                    if (projects.isEmpty) {
                      return const Center(
                        child: Text(
                          'No projects found.',
                          style: TextStyle(
                            color: Color(0xFF6F6F6F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemBuilder: (context, index) {
                        final data = projects[index];
                        final status = _controller.statusFor(data.projectName);

                        return BroilerProjectCard(
                          project: BroilerProjectItem(
                            title: data.projectName,
                            status: status == BroilerWorkflowStatus.inProgress
                                ? 'In Progress'
                                : 'Drafted',
                            statusType:
                                status == BroilerWorkflowStatus.inProgress
                                ? BroilerProjectStatus.inProgress
                                : BroilerProjectStatus.drafted,
                            trialDate: data.trialDate,
                            trialHouse: data.trialHouse,
                          ),
                          onTap: () {
                            final initialStep =
                                status == BroilerWorkflowStatus.inProgress
                                ? 0
                                : _controller.lastOpenedStepFor(
                                    data.projectName,
                                  );

                            Get.to(
                              () => BroilerProjectStepperPage(
                                projectName: data.projectName,
                                initialStep: initialStep,
                                readOnly: _controller.isReadOnly(
                                  data.projectName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemCount: projects.length,
                    );
                  }),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                _controller.clearForm();

                final dietMappingController =
                    Get.isRegistered<DietMappingController>()
                    ? Get.find<DietMappingController>()
                    : Get.put(DietMappingController(), permanent: true);
                dietMappingController.clearRuntimeState();

                final sampleDocController =
                    Get.isRegistered<SampleDocController>()
                    ? Get.find<SampleDocController>()
                    : Get.put(SampleDocController());
                sampleDocController.clearSampleData();

                Get.to(() => const BroilerProjectStepperPage());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateFilterButtonLabel() {
    if (_filterFromDate == null && _filterToDate == null) {
      return 'Date';
    }

    final from = _formatDate(_filterFromDate!);
    final to = _formatDate(_filterToDate ?? _filterFromDate!);
    if (_filterFromDate != null && _filterToDate != null) {
      if (_isSameDay(_filterFromDate!, _filterToDate!)) {
        return from;
      }
      return '$from - $to';
    }

    return from;
  }

  bool _matchesDateFilter(String trialDate) {
    if (_filterFromDate == null && _filterToDate == null) return true;

    final projectDate = _parseTrialDate(trialDate);
    if (projectDate == null) return false;

    final start = _filterFromDate ?? _filterToDate!;
    final end = _filterToDate ?? _filterFromDate!;
    return !projectDate.isBefore(
          DateTime(start.year, start.month, start.day),
        ) &&
        !projectDate.isAfter(DateTime(end.year, end.month, end.day));
  }

  DateTime? _parseTrialDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _showDateFilterSheet(BuildContext context) async {
    _DateFilterOption selectedOption =
        _selectedFilterOption ?? _DateFilterOption.none;
    DateTime? tempFrom = _filterFromDate;
    DateTime? tempTo = _filterToDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            DateTime startForPreset(_DateFilterOption option) {
              if (option == _DateFilterOption.last7Days) {
                return today.subtract(const Duration(days: 6));
              }
              if (option == _DateFilterOption.last30Days) {
                return today.subtract(const Duration(days: 29));
              }
              return today.subtract(const Duration(days: 89));
            }

            void selectPreset(_DateFilterOption option) {
              setSheetState(() {
                selectedOption = option;
                if (option == _DateFilterOption.last7Days) {
                  tempTo = today;
                  tempFrom = startForPreset(option);
                } else if (option == _DateFilterOption.last30Days) {
                  tempTo = today;
                  tempFrom = startForPreset(option);
                } else if (option == _DateFilterOption.last90Days) {
                  tempTo = today;
                  tempFrom = startForPreset(option);
                }
              });
            }

            Future<void> pickFromDate() async {
              final selected = await showDatePicker(
                context: sheetContext,
                initialDate: tempFrom ?? today,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (selected != null) {
                setSheetState(() {
                  selectedOption = _DateFilterOption.custom;
                  tempFrom = DateTime(
                    selected.year,
                    selected.month,
                    selected.day,
                  );
                  if (tempTo != null && tempTo!.isBefore(tempFrom!)) {
                    tempTo = tempFrom;
                  }
                });
              }
            }

            Future<void> pickToDate() async {
              final selected = await showDatePicker(
                context: sheetContext,
                initialDate: tempTo ?? tempFrom ?? today,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (selected != null) {
                setSheetState(() {
                  selectedOption = _DateFilterOption.custom;
                  tempTo = DateTime(
                    selected.year,
                    selected.month,
                    selected.day,
                  );
                  if (tempFrom != null && tempTo!.isBefore(tempFrom!)) {
                    tempFrom = tempTo;
                  }
                });
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Builder(
                    builder: (context) {
                      final hasSelectedFilter =
                          selectedOption != _DateFilterOption.none ||
                          tempFrom != null ||
                          tempTo != null;
                      final isCustomSelected =
                          selectedOption == _DateFilterOption.custom;

                      return Column(
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
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Choose transaction date',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFilterOption =
                                        _DateFilterOption.none;
                                    _filterFromDate = null;
                                    _filterToDate = null;
                                  });

                                  final modalNavigator = Navigator.of(context);
                                  if (modalNavigator.canPop()) {
                                    modalNavigator.pop();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasSelectedFilter
                                      ? Colors.red
                                      : const Color(0xFFBDBDBD),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildFilterOptionTile(
                            title: 'Last 7 days',
                            subtitle:
                                '${_formatDate(startForPreset(_DateFilterOption.last7Days))} - ${_formatDate(today)}',
                            selected:
                                selectedOption == _DateFilterOption.last7Days,
                            onTap: () =>
                                selectPreset(_DateFilterOption.last7Days),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 14),
                          _buildFilterOptionTile(
                            title: 'Last 30 days',
                            subtitle:
                                '${_formatDate(startForPreset(_DateFilterOption.last30Days))} - ${_formatDate(today)}',
                            selected:
                                selectedOption == _DateFilterOption.last30Days,
                            onTap: () =>
                                selectPreset(_DateFilterOption.last30Days),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 14),
                          _buildFilterOptionTile(
                            title: 'Last 90 days',
                            subtitle:
                                '${_formatDate(startForPreset(_DateFilterOption.last90Days))} - ${_formatDate(today)}',
                            selected:
                                selectedOption == _DateFilterOption.last90Days,
                            onTap: () =>
                                selectPreset(_DateFilterOption.last90Days),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 14),
                          _buildFilterOptionTile(
                            title: 'Custom',
                            subtitle: '',
                            selected:
                                selectedOption == _DateFilterOption.custom,
                            onTap: () {
                              setSheetState(() {
                                selectedOption = _DateFilterOption.custom;
                                tempFrom ??= today;
                                tempTo ??= today;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomDateCard(
                                  label: 'From',
                                  value: !isCustomSelected || tempFrom == null
                                      ? 'Select date'
                                      : _formatDate(tempFrom!),
                                  selected: isCustomSelected,
                                  onTap: pickFromDate,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildCustomDateCard(
                                  label: 'To',
                                  value: !isCustomSelected || tempTo == null
                                      ? 'Select date'
                                      : _formatDate(tempTo!),
                                  selected: isCustomSelected,
                                  onTap: pickToDate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilterOption = selectedOption;
                                  if (selectedOption ==
                                      _DateFilterOption.none) {
                                    _filterFromDate = null;
                                    _filterToDate = null;
                                  } else if (selectedOption ==
                                      _DateFilterOption.custom) {
                                    _filterFromDate = tempFrom;
                                    _filterToDate = tempTo;
                                  } else if (selectedOption ==
                                          _DateFilterOption.last7Days ||
                                      selectedOption ==
                                          _DateFilterOption.last30Days ||
                                      selectedOption ==
                                          _DateFilterOption.last90Days) {
                                    _filterFromDate = tempFrom;
                                    _filterToDate = tempTo;
                                  } else {
                                    _filterFromDate = null;
                                    _filterToDate = null;
                                  }
                                });
                                Navigator.of(sheetContext).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Set filter',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOptionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1F1F1F),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF8A8A8A),
                width: 2,
              ),
            ),
            child: selected
                ? const Center(
                    child: Icon(
                      Icons.circle,
                      size: 15,
                      color: Color(0xFF22C55E),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateCard({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF9EF) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF22C55E) : const Color(0xFFE3E3E3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DateFilterOption { none, last7Days, last30Days, last90Days, custom }

class BroilerProjectCard extends StatelessWidget {
  const BroilerProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  static const double _statusBadgeWidth = 100;

  final BroilerProjectItem project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = switch (project.statusType) {
      BroilerProjectStatus.inProgress => const ProjectStatusStyle(
        textColor: Color(0xFFE2A800),
        borderColor: Color(0xFFF3CB54),
        backgroundColor: Color(0xFFFFFBEE),
      ),
      BroilerProjectStatus.drafted => const ProjectStatusStyle(
        textColor: Color(0xFF2E82D0),
        borderColor: Color(0xFF8CBCEC),
        backgroundColor: Color(0xFFF4FAFF),
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: _statusBadgeWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: statusStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusStyle.borderColor),
                    ),
                    child: Text(
                      project.status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusStyle.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFD8D8D8)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Trial Date',
                    value: project.trialDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.home_work_rounded,
                    label: 'Trial House',
                    value: project.trialHouse,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F5EA),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF22C55E), size: 26),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF3E3E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BroilerProjectItem {
  const BroilerProjectItem({
    required this.title,
    required this.status,
    required this.statusType,
    required this.trialDate,
    required this.trialHouse,
  });

  final String title;
  final String status;
  final BroilerProjectStatus statusType;
  final String trialDate;
  final String trialHouse;
}

enum BroilerProjectStatus { inProgress, drafted }

class ProjectStatusStyle {
  const ProjectStatusStyle({
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
}
