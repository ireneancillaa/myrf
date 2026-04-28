import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:myrf/pages/monitoring/male_birds_page.dart';

import '../controller/broiler_controller.dart';
import '../controller/user_session_controller.dart';
import '../models/home_models.dart';
import 'monitoring/infeed_page.dart';
import 'monitoring/depletion_page.dart';
import 'monitoring/feses_score_page.dart';
import 'monitoring/brooding_page.dart';
import 'monitoring/weighing_page.dart';
import 'broiler_page.dart';
import 'profile_page.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedBottomIndex = 0;
  String? _selectedFarm;
  late final BroilerController _broilerController;
  late final UserSessionController _sessionController;
  bool _isSummaryExpanded = false;

  final List<QuickActionItem> _quickActions = const [
    QuickActionItem(
      title: 'Infeed',
      iconAsset: 'assets/infeed.png',
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Depletion',
      iconAsset: 'assets/chicken.png',
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Weighing',
      iconAsset: 'assets/body-weight.png',
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Male Birds',
      iconAsset: 'assets/male.svg',
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Feses',
      iconAsset: 'assets/remarks.png',
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
    _sessionController = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);
  }

  String _displayValue(String? value, {String fallback = '-'}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _birdCountValue() {
    final raw = _displayValue(_broilerController.numberOfBirdsController.text);
    if (raw == '-') return raw;
    if (raw.toLowerCase().contains('birds')) return raw;
    return '$raw Birds';
  }

  List<String> _buildFarmOptions() {
    final cloudProjects = _broilerController.inProgressProjectNames;
    if (cloudProjects.isNotEmpty) {
      return cloudProjects;
    }
    return ['No Active Projects'];
  }

  Future<String?> _showFarmSelectionModal({
    required BuildContext context,
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
                    const Text(
                      'Choose Farm',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedValue == null || selectedValue.isEmpty
                          ? 'Current: Select Farm'
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
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedBottomIndex == 0 ? _buildAppBar() : null,
      body: IndexedStack(
        index: _selectedBottomIndex,
        children: [
          _buildHomeTab(),
          const BroilerPage(),
          const _PlaceholderTab(title: 'Layer'),
          const HistoryPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _selectedBottomIndex,
        indicatorColor: const Color(0xFF22C55E).withValues(alpha: 0.2),
        onDestinationSelected: (index) {
          setState(() {
            _selectedBottomIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF22C55E)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture, color: Color(0xFF22C55E)),
            label: 'Broiler',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers, color: Color(0xFF22C55E)),
            label: 'Layer',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF22C55E)),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFarmSummaryCard(),
            const SizedBox(height: 20),
            _buildBroodingHeader(),
            const SizedBox(height: 12),
            _buildBroodingGrid(),
            const SizedBox(height: 20),
            const Text(
              'Project Monitoring',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionGrid(),
            _buildProjectIncompleteSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: const Color(0xFF111827),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF111827)),
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      // toolbarHeight: 84,
      titleSpacing: 16,
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${_sessionController.displayName}',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            // const SizedBox(height: 4),
            // Text(
            //   'My Research Farm',
            //   style: const TextStyle(
            //     color: Color(0xFF6B7280),
            //     fontSize: 12,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
          },
          icon: const Icon(Icons.person, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String value,
    required String iconAsset,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          children: [
            Image.asset(iconAsset, width: 28, height: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmSummaryCard() {
    final hatchery = _displayValue(
      _broilerController.selectedHatchery.value ??
          _broilerController.hatcheryController.text,
    );
    final breedingFarm = _displayValue(
      _broilerController.breedingFarmController.text,
    );
    final docInDate = _displayValue(
      _broilerController.selectedDocInDate.value ??
          _broilerController.docInDateController.text,
    );
    final numberOfBirds = _birdCountValue();
    final diet = _displayValue(_broilerController.dietController.text);
    final replication = _displayValue(
      _broilerController.replicationController.text,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            _broilerController.projectStatuses.toString();
            final farmOptions = _buildFarmOptions();
            final inProgressNames = _broilerController.inProgressProjectNames;

            // Ensure we are showing an In Progress project if available
            final selectedValue = inProgressNames.contains(_selectedFarm)
                ? _selectedFarm
                : (inProgressNames.isNotEmpty
                      ? inProgressNames.first
                      : farmOptions.first);

            if (_selectedFarm != selectedValue) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedFarm = selectedValue);
                if (inProgressNames.contains(selectedValue)) {
                  _broilerController.selectProjectByName(selectedValue);
                }
              });
            }

            return InkWell(
              onTap: () async {
                final picked = await _showFarmSelectionModal(
                  context: context,
                  options: farmOptions,
                  selectedValue: selectedValue,
                );

                if (picked == null) return;

                setState(() => _selectedFarm = picked);

                if (_broilerController.inProgressProjectNames.contains(
                  picked,
                )) {
                  _broilerController.selectProjectByName(picked);
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedValue ?? 'Select Farm',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: Color(0xFF1E1E1E),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoBox(
                title: 'Breeding Farm',
                value: breedingFarm,
                iconAsset: 'assets/breeding-farm.png',
                bgColor: const Color(0xFFFFFBF3),
              ),
              const SizedBox(width: 12),
              _buildInfoBox(
                title: 'Number of Birds',
                value: numberOfBirds,
                iconAsset: 'assets/number-of-birds.png',
                bgColor: const Color(0xFFF3FCF7),
              ),
            ],
          ),
          if (_isSummaryExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBox(
                  title: 'Diet',
                  value: diet,
                  iconAsset: 'assets/diet-replication.png',
                  bgColor: const Color(0xFFE8F5EE),
                ),
                const SizedBox(width: 12),
                _buildInfoBox(
                  title: 'Replication',
                  value: replication,
                  iconAsset: 'assets/diet-replication.png',
                  bgColor: const Color(0xFFFFF1D9),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBox(
                  title: 'Hatchery',
                  value: hatchery,
                  iconAsset: 'assets/hatchery.png',
                  bgColor: const Color(0xFFF4F9FF),
                ),
                const SizedBox(width: 12),
                _buildInfoBox(
                  title: 'DOC In Date',
                  value: docInDate,
                  iconAsset: 'assets/doc-in-date.png',
                  bgColor: const Color(0xFFFEF2F2),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() {
                _isSummaryExpanded = !_isSummaryExpanded;
              });
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSummaryExpanded ? 'View Less' : 'View Details',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isSummaryExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF22C55E),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(_quickActions.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFEAEAEA),
              );
            }

            final action = _quickActions[index ~/ 2];
            return Expanded(child: _buildQuickActionItem(action));
          }),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(QuickActionItem action) {
    VoidCallback? onTap;

    void navigateWithMessage(Widget page) {
      final projectId = _broilerController.selectedProjectId.value;
      if (projectId == null || projectId.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a project first.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    switch (action.title) {
      case 'Infeed':
        onTap = () => navigateWithMessage(const InfeedPage());
        break;
      case 'Depletion':
        onTap = () => navigateWithMessage(const DepletionPage());
        break;
      case 'Weighing':
        onTap = () =>
            navigateWithMessage(WeighingPage(selectedFarmName: _selectedFarm));
        break;
      case 'Male Birds':
        onTap = () => navigateWithMessage(const MaleBirdsPage());
        break;
      case 'Feses':
        onTap = () => navigateWithMessage(const FesesScorePage());
        break;
      default:
        onTap = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: action.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: action.iconAsset.endsWith('.svg')
                    ? SvgPicture.asset(action.iconAsset, width: 28, height: 28)
                    : Image.asset(
                        action.iconAsset,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: Center(
                child: Text(
                  action.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroodingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Environment Temperature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BroodingPage(selectedFarmName: _selectedFarm),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.remove_red_eye_outlined,
                  color: Color(0xFF22C55E),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBroodingGrid() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildBroodingCard(
              BroodingCardItem(
                icon: Icons.thermostat,
                value: _broilerController.frontTemp.value,
                label: 'Front Area',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildBroodingCard(
              BroodingCardItem(
                icon: Icons.thermostat,
                value: _broilerController.middleTemp.value,
                label: 'Middle Area',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildBroodingCard(
              BroodingCardItem(
                icon: Icons.thermostat,
                value: _broilerController.rearTemp.value,
                label: 'Rear Area',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroodingCard(BroodingCardItem item) {
    final temperature = _temperatureFromValue(item.value);
    final indicatorColor = _temperatureColor(temperature, area: item.label);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.05),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: indicatorColor, size: 18),
              const SizedBox(width: 4),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: indicatorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double? _temperatureFromValue(String value) {
    final normalized = value.replaceAll('°C', '').trim();
    return double.tryParse(normalized);
  }

  Color _temperatureColor(double? temperature, {String? area}) {
    if (temperature == null) return const Color(0xFF2E9DEB);

    final standard = _broilerController.currentTemperatureStandard.value;
    if (standard == null) {
      if (temperature <= 27) return const Color(0xFF2E9DEB);
      if (temperature <= 31) return const Color(0xFFE6A10B);
      return const Color(0xFFE94949);
    }

    // Global Stats (Min/Max Temperature)
    if (area == null) {
      if (temperature < standard.min) return const Color(0xFF2E9DEB);
      if (temperature > standard.max) return const Color(0xFFE94949);
      return const Color(0xFF22C55E);
    }

    // Area-specific targets (Front, Middle, Rear)
    double target = standard.front;
    if (area.toLowerCase().contains('middle')) {
      target = standard.middle;
    } else if (area.toLowerCase().contains('rear')) {
      target = standard.rear;
    }

    const tolerance = 1.0;
    if (temperature < target - tolerance) return const Color(0xFF2E9DEB);
    if (temperature > target + tolerance) return const Color(0xFFE94949);
    return const Color(0xFF22C55E);
  }

  Widget _buildProjectIncompleteSection() {
    return Obx(() {
      final draftedProjects = _broilerController.projects
          .where(
            (p) =>
                _broilerController.statusFor(p.projectId) ==
                BroilerWorkflowStatus.drafted,
          )
          .toList();

      if (draftedProjects.isEmpty) return const SizedBox.shrink();

      draftedProjects.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime(1970);
        final bTime = b.updatedAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      final firstDraft = draftedProjects.first;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Project Incomplete',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _selectedBottomIndex = 1;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEBEBEB)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7E3),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${draftedProjects.length} Project Incomplete',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF737373),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  firstDraft.projectName,
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
                              width: 100,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4FAFF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF8CBCEC),
                                  ),
                                ),
                                child: const Text(
                                  'Drafted',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF2E82D0),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE6F5EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF22C55E),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Trial Date',
                                          style: TextStyle(
                                            color: Color(0xFF8A8A8A),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          firstDraft.trialDate,
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
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE6F5EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.home_work_rounded,
                                      color: Color(0xFF22C55E),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Trial House',
                                          style: TextStyle(
                                            color: Color(0xFF8A8A8A),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          firstDraft.trialHouse,
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
          ),
        ],
      );
    });
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title page is not available yet',
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF6D6D6D),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
