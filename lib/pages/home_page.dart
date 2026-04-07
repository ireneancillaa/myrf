import 'package:flutter/material.dart';

import 'broiler_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedBottomIndex = 0;
  String _selectedFarm = 'test';

  final List<String> _farmOptions = ['test', 'Farm B', 'Farm C'];

  final List<_QuickActionItem> _quickActions = const [
    _QuickActionItem(
      title: 'Weighing DOA',
      icon: Icons.scale_outlined,
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE8F5EE),
    ),
    _QuickActionItem(
      title: 'Infeed',
      icon: Icons.soup_kitchen_outlined,
      iconColor: Color(0xFF22C55E),
      iconBgColor: Color(0xFFE6F8F0),
    ),
    _QuickActionItem(
      title: 'Depletion',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFE44B4B),
      iconBgColor: Color(0xFFFBEDED),
    ),
    _QuickActionItem(
      title: 'Feses Score',
      icon: Icons.science,
      iconColor: Color(0xFFE6A10B),
      iconBgColor: Color(0xFFFCF6E8),
    ),
  ];

  final List<_BroodingCardItem> _broodingRows = const [
    _BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFFE69C00),
      value: '32.5°C',
      valueColor: Color(0xFFE69C00),
      label: 'R. Depan',
    ),
    _BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFFE94949),
      value: '33.0°C',
      valueColor: Color(0xFFE94949),
      label: 'R. Tengah',
    ),
    _BroodingCardItem(
      icon: Icons.thermostat,
      iconColor: Color(0xFF2E9DEB),
      value: '31.8°C',
      valueColor: Color(0xFF2E9DEB),
      label: 'R. Belakang',
    ),
    _BroodingCardItem(
      icon: Icons.arrow_downward_rounded,
      iconColor: Color(0xFF2E9DEB),
      value: '28.5°C',
      valueColor: Color(0xFF2E9DEB),
      label: 'Min Temperature',
    ),
    _BroodingCardItem(
      icon: Icons.arrow_upward_rounded,
      iconColor: Color(0xFFE94949),
      value: '35.2°C',
      valueColor: Color(0xFFE94949),
      label: 'Max Temperature',
    ),
  ];

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
            const SizedBox(height: 16),
            _buildQuickActionGrid(),
            const SizedBox(height: 28),
            _buildBroodingHeader(),
            const SizedBox(height: 14),
            _buildBroodingGrid(),
            const SizedBox(height: 18),
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
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome, Farm Breeder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'My Research Farm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFarm,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                items: _farmOptions
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
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 10),
          const _InfoRow(label: 'Strain', value: 'Cobb 500'),
          const _InfoRow(label: 'Hatchery', value: 'Main Hatchery'),
          const _InfoRow(label: 'Breeding Farm', value: 'Farm A'),
          const _InfoRow(label: 'DOC In Date', value: '7/4/2026'),
          const _InfoRow(label: 'Number of Birds', value: '100'),
          const _InfoRow(label: 'Diet/Replication', value: '4', isLast: true),
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

  Widget _buildQuickActionItem(_QuickActionItem action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildBroodingHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Brooding Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1D21),
          ),
        ),
        Row(
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

  Widget _buildBroodingCard(_BroodingCardItem item) {
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 2 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6D6D6D),
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF202124),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
}

class _BroodingCardItem {
  const _BroodingCardItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
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
