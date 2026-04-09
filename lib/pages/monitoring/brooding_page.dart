import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';

class BroodingPage extends StatefulWidget {
  const BroodingPage({super.key, this.selectedFarmName});

  final String? selectedFarmName;

  @override
  State<BroodingPage> createState() => _BroodingPageState();
}

class _BroodingPageState extends State<BroodingPage> {
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFF1F2937);

  late final BroilerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Brooding',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: Obx(() {
        final selectedProject = _controller.selectedProjectName.value;
        final selectedFarmName = widget.selectedFarmName?.trim() ?? '';
        final hasProject =
            selectedProject != null && selectedProject.trim().isNotEmpty;
        final hasFarmContext = selectedFarmName.isNotEmpty;

        if (!hasProject && !hasFarmContext) {
          return const Center(child: Text('Please select a project first'));
        }

        final contextName = hasProject ? selectedProject : selectedFarmName;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contextName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: _primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Temperature data is automatically recorded by IoT devices. This page displays real-time readings.',
                        style: TextStyle(
                          color: _primaryGreen.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Temperature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTemperatureCard(
                      title: 'R. Depan',
                      value: '32.5°C',
                      icon: Icons.thermostat,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTemperatureCard(
                      title: 'R. Tengah',
                      value: '33.0°C',
                      icon: Icons.thermostat,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTemperatureCard(
                      title: 'R. Belakang',
                      value: '31.8°C',
                      icon: Icons.thermostat,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Daily Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTemperatureCardMinMax(
                      title: 'Minimum Temperature',
                      value: 28.5,
                      icon: Icons.arrow_downward,
                      color: Colors.blue,
                      isLarge: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTemperatureCardMinMax(
                      title: 'Maximum Temperature',
                      value: 35.2,
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                      isLarge: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Temperature Per Hour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildHourlyTemperatureChart(),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Last updated: ${_formatDateTime(DateTime.now())}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTemperatureCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmall ? 20 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCardMinMax({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${value.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: isLarge ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyTemperatureChart() {
    final hourlyData = <Map<String, Object>>[
      {'hour': '00:00', 'temp': 29.5},
      {'hour': '02:00', 'temp': 28.8},
      {'hour': '04:00', 'temp': 28.5},
      {'hour': '06:00', 'temp': 29.2},
      {'hour': '08:00', 'temp': 30.5},
      {'hour': '10:00', 'temp': 32.0},
      {'hour': '12:00', 'temp': 34.5},
      {'hour': '14:00', 'temp': 35.2},
      {'hour': '16:00', 'temp': 34.0},
      {'hour': '18:00', 'temp': 32.5},
      {'hour': '20:00', 'temp': 31.0},
      {'hour': '22:00', 'temp': 30.0},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: hourlyData.map((data) {
          final temp = data['temp'] as num;
          final heightPercent = (temp - 28) / 8;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${temp.toStringAsFixed(1)}°',
                style: const TextStyle(fontSize: 10, color: _primaryGreen),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 120 * heightPercent,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_primaryGreen.withOpacity(0.3), _primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Transform.rotate(
                angle: -0.5,
                child: Text(
                  data['hour'] as String,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
