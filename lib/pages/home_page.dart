import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/broiler_controller.dart';
import '../controller/diet_mapping_controller.dart';
import '../controller/user_session_controller.dart';
import '../models/home_models.dart';
import 'monitoring/infeed_page.dart';
import 'monitoring/depletion_page.dart';
import 'monitoring/feses_score_page.dart';
import 'monitoring/brooding_page.dart';
import 'monitoring/weighing_doa_page.dart';
import 'broiler_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedBottomIndex = 0;
  String? _selectedFarm;
  late final BroilerController _broilerController;
  late final DietMappingController _dietMappingController;
  late final UserSessionController _sessionController;


  final List<QuickActionItem> _quickActions = const [
    QuickActionItem(
      title: 'Weigh',
      icon: Icons.hourglass_empty_rounded,
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Infeed',
      icon: Icons.soup_kitchen_rounded,
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Depletion',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFE94949),
      iconBgColor: Color(0xFFFBEDED),
    ),
    QuickActionItem(
      title: 'Feses',
      icon: Icons.science_rounded,
      iconColor: Color(0xFFE6A10B),
      iconBgColor: Color(0xFFFCF6E8),
    ),
  ];
  final List<BroodingCardItem> _broodingRows = const [
    BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFFE6A10B),
      value: '32.5°C',
      valueColor: Color(0xFFE6A10B),
      label: 'R. Depan',
    ),
    BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFFE94949),
      value: '33.0°C',
      valueColor: Color(0xFFE94949),
      label: 'R. Tengah',
    ),
    BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFF2E9DEB),
      value: '31.8°C',
      valueColor: Color(0xFF2E9DEB),
      label: 'R. Belakang',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
    _dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
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
          const _PlaceholderTab(title: 'History'),
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
              'Quick Actions',
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
      backgroundColor: const Color(0xFF22C55E),
      elevation: 0,
      toolbarHeight: 84,
      titleSpacing: 16,
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${_sessionController.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'My Research Farm',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          icon: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFarmSummaryCard() {
    final strain = _displayValue(
      _broilerController.selectedStrain.value ??
          _broilerController.strainController.text,
    );
    final hatchery = _displayValue(
      _broilerController.selectedHatchery.value ??
          _broilerController.hatcheryController.text,
    );
    final breedingFarm = _displayValue(_broilerController.breedingFarmController.text);
    final docInDate = _displayValue(
      _broilerController.selectedDocInDate.value ??
          _broilerController.docInDateController.text,
    );
    final numberOfBirds = _birdCountValue();

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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D9), // Previous strain background
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/strain.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFarm ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strain,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
              ),
              // Dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDADADA)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() {
                  _broilerController.projectStatuses.toString();
                  final farmOptions = _buildFarmOptions();
                  final selectedValue = farmOptions.contains(_selectedFarm)
                      ? _selectedFarm
                      : farmOptions.first;
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: Colors.white,
                      value: selectedValue,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Color(0xFF555555),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      items: farmOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedFarm = value);

                        if (_broilerController.inProgressProjectNames.contains(
                          value,
                        )) {
                          _broilerController.selectProject(value);
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hatchery
          Row(
            children: [
              Image.asset('assets/hatchery.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text(
                'Hatchery: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              Text(
                hatchery,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // DOC In Date
          Row(
            children: [
              Image.asset('assets/doc-in-date.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text(
                'DOC In Date: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              Text(
                docInDate,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Breeding Farm & Number of Birds
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF3),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/breeding-farm.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Breeding Farm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            Text(
                              breedingFarm,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3FCF7),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/number-of-birds.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Number of Birds',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            Text(
                              numberOfBirds,
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
              ),
            ],
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

    switch (action.title) {
      case 'Weighing DOA':
        onTap = () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WeighingDoaPage(selectedFarmName: _selectedFarm),
            ),
          );
        };
        break;
      case 'Infeed':
        onTap = () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const InfeedPage()));
        };
        break;
      case 'Depletion':
        onTap = () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DepletionPage()));
        };
        break;
      case 'Feces Score':
        onTap = () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FesesScorePage()));
        };
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: action.iconColor, size: 28),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  action.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
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
          'Brooding Temperature',
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
    return Row(
      children: [
        Expanded(child: _buildBroodingCard(_broodingRows[0])),
        const SizedBox(width: 10),
        Expanded(child: _buildBroodingCard(_broodingRows[1])),
        const SizedBox(width: 10),
        Expanded(child: _buildBroodingCard(_broodingRows[2])),
      ],
    );
  }

  Widget _buildBroodingCard(BroodingCardItem item) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: item.iconColor.withValues(alpha: 0.05),
        border: Border.all(color: item.iconColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.iconColor, size: 18),
              const SizedBox(width: 4),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: item.valueColor,
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

  Widget _buildProjectIncompleteSection() {
    return Obx(() {
      final draftedProjects = _broilerController.projects
          .where(
            (p) =>
                _broilerController.statusFor(p.projectName) ==
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
          Container(
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
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FAFF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF8CBCEC)),
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
                                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF22C55E), size: 26),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Trial Date',
                                        style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        firstDraft.trialDate,
                                        style: const TextStyle(color: Color(0xFF3E3E3E), fontSize: 16, fontWeight: FontWeight.w700),
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
                                  child: const Icon(Icons.home_work_rounded, color: Color(0xFF22C55E), size: 26),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Trial House',
                                        style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        firstDraft.trialHouse,
                                        style: const TextStyle(color: Color(0xFF3E3E3E), fontSize: 16, fontWeight: FontWeight.w700),
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
