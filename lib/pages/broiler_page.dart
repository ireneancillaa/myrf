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
        backgroundColor: const Color(0xFF22C55E),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Broiler Project List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            final projects = _controller.projects;
            // Trigger rebuild when projectStatuses changes
            _controller.projectStatuses.toString();

            if (projects.isEmpty) {
              return const Center(
                child: Text(
                  'No projects yet. Click + Project to create one.',
                  style: TextStyle(
                    color: Color(0xFF6F6F6F),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemBuilder: (context, index) {
                final data = projects[index];
                final status = _controller.statusFor(data.projectName);

                return _BroilerProjectCard(
                  project: _BroilerProjectItem(
                    title: data.projectName,
                    status: status == BroilerWorkflowStatus.inProgress
                        ? 'In Progress'
                        : 'Drafted',
                    statusType: status == BroilerWorkflowStatus.inProgress
                        ? _BroilerProjectStatus.inProgress
                        : _BroilerProjectStatus.drafted,
                    trialDate: data.trialDate,
                    trialHouse: data.trialHouse,
                  ),
                  onTap: () {
                    final initialStep =
                        status == BroilerWorkflowStatus.inProgress
                        ? 0
                        : _controller.lastOpenedStepFor(data.projectName);

                    Get.to(
                      () => BroilerProjectStepperPage(
                        projectName: data.projectName,
                        initialStep: initialStep,
                        readOnly: _controller.isReadOnly(data.projectName),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemCount: projects.length,
            );
          }),
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
}

class _BroilerProjectCard extends StatelessWidget {
  const _BroilerProjectCard({required this.project, required this.onTap});

  static const double _statusBadgeWidth = 100;

  final _BroilerProjectItem project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = switch (project.statusType) {
      _BroilerProjectStatus.inProgress => const _ProjectStatusStyle(
        textColor: Color(0xFFE2A800),
        borderColor: Color(0xFFF3CB54),
        backgroundColor: Color(0xFFFFFBEE),
      ),
      _BroilerProjectStatus.drafted => const _ProjectStatusStyle(
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

class _BroilerProjectItem {
  const _BroilerProjectItem({
    required this.title,
    required this.status,
    required this.statusType,
    required this.trialDate,
    required this.trialHouse,
  });

  final String title;
  final String status;
  final _BroilerProjectStatus statusType;
  final String trialDate;
  final String trialHouse;
}

enum _BroilerProjectStatus { inProgress, drafted }

class _ProjectStatusStyle {
  const _ProjectStatusStyle({
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
}
