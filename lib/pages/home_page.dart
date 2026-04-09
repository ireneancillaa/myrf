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
  String _selectedFarm = 'Farm B';
  late final BroilerController _broilerController;
  late final DietMappingController _dietMappingController;
  late final UserSessionController _sessionController;

  static const List<String> _sampleFarmOptions = ['Farm B', 'Farm C'];
  static const Map<String, SampleFarmInfo> _sampleFarmInfo = {
    'Farm B': SampleFarmInfo(
      strain: 'Ross 308',
      hatchery: 'North Hatchery',
      breedingFarm: 'Farm B',
      docInDate: '08/04/2026',
      numberOfBirds: '120 Ekor',
      dietReplication: '3',
    ),
    'Farm C': SampleFarmInfo(
      strain: 'Hubbard',
      hatchery: 'South Hatchery',
      breedingFarm: 'Farm C',
      docInDate: '09/04/2026',
      numberOfBirds: '150 Ekor',
      dietReplication: '4',
    ),
  };

  final List<QuickActionItem> _quickActions = const [
    QuickActionItem(
      title: 'Weighing DOA',
      icon: Icons.scale_outlined,
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    QuickActionItem(
      title: 'Infeed',
      icon: Icons.soup_kitchen_outlined,
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE6F8F0),
    ),
    QuickActionItem(
      title: 'Depletion',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFE44B4B),
      iconBgColor: Color(0xFFFBEDED),
    ),
    QuickActionItem(
      title: 'Feses Score',
      icon: Icons.science,
      iconColor: Color(0xFFE6A10B),
      iconBgColor: Color(0xFFFCF6E8),
    ),
  ];

  final List<BroodingCardItem> _broodingRows = const [
    BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFFE69C00),
      value: '32.5°C',
      valueColor: Color(0xFFE69C00),
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
    BroodingCardItem(
      icon: Icons.arrow_downward_rounded,
      iconColor: Color(0xFF2E9DEB),
      value: '28.5°C',
      valueColor: Color(0xFF2E9DEB),
      label: 'Min Temperature',
    ),
    BroodingCardItem(
      icon: Icons.arrow_upward_rounded,
      iconColor: Color(0xFFE94949),
      value: '35.2°C',
      valueColor: Color(0xFFE94949),
      label: 'Max Temperature',
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
    if (raw.toLowerCase().contains('ekor')) return raw;
    return '$raw Ekor';
  }

  List<String> _buildFarmOptions() {
    return [
      ..._sampleFarmOptions,
      ..._broilerController.projectNames.where(
        (name) => !_sampleFarmOptions.contains(name),
      ),
    ];
  }

  List<FarmInfoCardItem> _buildFarmInfoItems() {
    final selectedSample = _sampleFarmInfo[_selectedFarm];

    return [
      FarmInfoCardItem(
        label: 'Strain',
        value:
            selectedSample?.strain ??
            _displayValue(
              _broilerController.selectedStrain.value ??
                  _broilerController.strainController.text,
            ),
        iconAsset: 'assets/strain.png',
        iconBgColor: const Color(0xFFFFF1D9),
        cardBgColor: const Color(0xFFFFFBF3),
      ),
      FarmInfoCardItem(
        label: 'Hatchery',
        value:
            selectedSample?.hatchery ??
            _displayValue(
              _broilerController.selectedHatchery.value ??
                  _broilerController.hatcheryController.text,
            ),
        iconAsset: 'assets/hatchery.png',
        iconBgColor: const Color(0xFFDFF5E9),
        cardBgColor: const Color(0xFFF3FCF7),
      ),
      FarmInfoCardItem(
        label: 'Breeding Farm',
        value:
            selectedSample?.breedingFarm ??
            _displayValue(_broilerController.breedingFarmController.text),
        iconAsset: 'assets/breeding-farm.png',
        iconBgColor: const Color(0xFFFFF1D9),
        cardBgColor: const Color(0xFFFFFBF3),
      ),
      FarmInfoCardItem(
        label: 'DOC In Date',
        value:
            selectedSample?.docInDate ??
            _displayValue(
              _broilerController.selectedDocInDate.value ??
                  _broilerController.docInDateController.text,
            ),
        iconAsset: 'assets/doc-in-date.png',
        iconBgColor: const Color(0xFFDFF5E9),
        cardBgColor: const Color(0xFFF3FCF7),
      ),
      FarmInfoCardItem(
        label: 'Jumlah Ayam',
        value: selectedSample?.numberOfBirds ?? _birdCountValue(),
        iconAsset: 'assets/number-of-birds.png',
        iconBgColor: const Color(0xFFDFF5E9),
        cardBgColor: const Color(0xFFF3FCF7),
      ),
      FarmInfoCardItem(
        label: 'Diet/Replicasi',
        value:
            selectedSample?.dietReplication ??
            (_dietMappingController.dietReplication.value?.toString() ?? '-'),
        iconAsset: 'assets/diet-replication.png',
        iconBgColor: const Color(0xFFE7F5F8),
        cardBgColor: const Color(0xFFF4FBFD),
      ),
    ];
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
        indicatorColor: const Color(0xFF22C55E).withOpacity(0.2),
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
            const SizedBox(height: 14),
            _buildQuickActionGrid(),
            const SizedBox(height: 16),
            _buildBroodingHeader(),
            const SizedBox(height: 1),
            _buildBroodingGrid(),
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
    final farmInfoItems = _buildFarmInfoItems();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDADADA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() {
              final farmOptions = _buildFarmOptions();
              final selectedValue = farmOptions.contains(_selectedFarm)
                  ? _selectedFarm
                  : farmOptions.first;

              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  items: farmOptions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFarm = value);

                    if (_broilerController.projectNames.contains(value)) {
                      _broilerController.selectProject(value);
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: farmInfoItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 60,
            ),
            itemBuilder: (context, index) {
              return _InfoGridCard(item: farmInfoItems[index]);
            },
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
      case 'Feses Score':
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
          'Brooding Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1D21),
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
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 120,
          ),
          itemBuilder: (context, index) {
            return _buildBroodingCard(_broodingRows[index]);
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildBroodingCard(_broodingRows[3])),
            const SizedBox(width: 12),
            Expanded(child: _buildBroodingCard(_broodingRows[4])),
          ],
        ),
      ],
    );
  }

  Widget _buildBroodingCard(BroodingCardItem item) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.iconColor, size: 30),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: item.valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF737373),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGridCard extends StatelessWidget {
  const _InfoGridCard({required this.item});

  final FarmInfoCardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                item.iconAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFF9CA3AF),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title page belum tersedia',
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
