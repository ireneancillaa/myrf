import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/broiler_controller.dart';
import '../controller/sample_doc_controller.dart';
import 'broiler/sample_doc.dart';
import 'broiler/diet_pen_mapping.dart';
import 'broiler/project_information.dart';

class BroilerPage extends StatefulWidget {
  const BroilerPage({super.key});

  @override
  State<BroilerPage> createState() => _BroilerPageState();
}

class _BroilerPageState extends State<BroilerPage> {
  late final BroilerController controller;
  late final SampleDocController sampleDocController;
  late final ScrollController _scrollController;
  int _currentStep = 0;
  static const _stepCount = 3;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    controller = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);
    sampleDocController = Get.isRegistered<SampleDocController>()
        ? Get.find<SampleDocController>()
        : Get.put(SampleDocController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<SampleDocController>()) {
      Get.delete<SampleDocController>();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
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
          'Broiler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: BroilerStepperTabs(
                currentStep: _currentStep,
                totalSteps: _stepCount,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentStepContent(),
                    SizedBox(height: _currentStep == 2 ? 0 : 24),
                    if (_currentStep == 0)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final isSaved = controller.saveProject();
                            if (isSaved) {
                              _goToStep(1);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () {
                                  _goToStep(_currentStep - 1);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF22C55E),
                                  side: const BorderSide(
                                    color: Color(0xFF22C55E),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_currentStep < 2) {
                                    _goToStep(_currentStep + 1);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Data berhasil disimpan'),
                                        backgroundColor: Color(0xFF22C55E),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _currentStep < 2 ? 'Next' : 'Finish',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return BroilerProjectInformationSection(controller: controller);
      case 1:
        return DietPenMappingSection(controller: controller);
      case 2:
        return SampleDocSection(
          boxHeaviestController: sampleDocController.boxHeaviestController,
          boxAverageController: sampleDocController.boxAverageController,
          boxLightestController: sampleDocController.boxLightestController,
          docWeights: sampleDocController.docWeights,
          onDocWeightsChanged: (weights) {
            sampleDocController.docWeights.assignAll(weights);
          },
          docDistributions: sampleDocController.docDistributions,
          onDocDistributionsChanged: (distributions) {
            sampleDocController.docDistributions.assignAll(distributions);
          },
          dietReplication: controller.dietReplication.value ?? 1,
          totalPens: sampleDocController.totalPens.value,
        );
      default:
        return BroilerProjectInformationSection(controller: controller);
    }
  }
}

class BroilerStepperTabs extends StatelessWidget {
  const BroilerStepperTabs({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  static const double _stepperHeight = 70;
  static const double _lineTop = 21;
  static const double _lineHeight = 2;

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final safeStep = currentStep.clamp(0, totalSteps - 1);
    final progress = totalSteps <= 1 ? 0.0 : safeStep / (totalSteps - 1);

    return SizedBox(
      height: _stepperHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final progressWidth = constraints.maxWidth * progress;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: _lineTop,
                left: 0,
                right: 0,
                child: Container(
                  height: _lineHeight,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              Positioned(
                top: _lineTop,
                left: 0,
                child: Container(
                  width: progressWidth,
                  height: _lineHeight,
                  color: const Color(0xFF22C55E),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BroilerStepTab(
                    icon: Icons.assignment_rounded,
                    label: 'Project Planning',
                    active: safeStep >= 0,
                  ),
                  _BroilerStepTab(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Diet & Pen Mapping',
                    active: safeStep >= 1,
                  ),
                  _BroilerStepTab(
                    icon: Icons.science_rounded,
                    label: 'Sample DOC',
                    active: safeStep >= 2,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BroilerStepTab extends StatelessWidget {
  const _BroilerStepTab({
    required this.icon,
    required this.label,
    required this.active,
  });

  static const double _iconCardSize = 42;
  static const double _iconSize = 24;

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF22C55E) : const Color(0xFFC9C9C9);
    final backgroundColor = active
        ? const Color(0xFFE2F2E7)
        : const Color(0xFFF1F1F1);

    return Column(
      children: [
        Container(
          width: _iconCardSize,
          height: _iconCardSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: color, size: _iconSize),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
