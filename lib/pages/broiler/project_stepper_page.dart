import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/broiler_controller.dart';
import '../../controller/diet_mapping_controller.dart';
import '../../controller/sample_doc_controller.dart';
import '../../controller/infeed_controller.dart';
import '../../controller/mortality_controller.dart';
import '../../controller/weighing_controller.dart';
import '../../controller/male_birds_controller.dart';
import '../../controller/feses_controller.dart';
// import '../../services/pdf_generator_service.dart';
import 'project_pdf_preview_page.dart';
import 'sample_doc.dart';
import 'diet_pen_mapping.dart';
import 'project_information.dart';

class BroilerProjectStepperPage extends StatefulWidget {
  const BroilerProjectStepperPage({
    super.key,
    this.projectId,
    this.projectName,
    this.initialStep = 0,
    this.readOnly = false,
  });

  final String? projectId;
  final String? projectName;
  final int initialStep;
  final bool readOnly;

  @override
  State<BroilerProjectStepperPage> createState() =>
      _BroilerProjectStepperPageState();
}

class _BroilerProjectStepperPageState extends State<BroilerProjectStepperPage> {
  late final BroilerController controller;
  late final DietMappingController dietMappingController;
  late final SampleDocController sampleDocController;
  final GlobalKey<FormState> _projectInfoFormKey = GlobalKey<FormState>();
  late final ScrollController _scrollController;
  late bool _isReadOnly;
  late bool _openedFromDraft;
  bool _showProjectInfoValidation = false;
  bool _isUploadingAttachments = false;
  String? _projectId;
  String? _projectName;
  int _currentStep = 0;
  static const _stepCount = 3;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Controller utama WAJIB hanya Get.find, tidak boleh Get.put di sini!
    controller = Get.find<BroilerController>();
    dietMappingController = Get.find<DietMappingController>();
    // SampleDocController boleh Get.put jika belum ada (karena child)
    sampleDocController = Get.isRegistered<SampleDocController>()
        ? Get.find<SampleDocController>()
        : Get.put(SampleDocController());

    _isReadOnly = widget.readOnly;
    _openedFromDraft = false;
    _projectId = widget.projectId;
    _projectName = widget.projectName;
    _currentStep = widget.initialStep.clamp(0, _stepCount - 1);

    if (_projectId != null && _projectId!.isNotEmpty) {
      _openedFromDraft =
          controller.statusFor(_projectId!) == BroilerWorkflowStatus.drafted;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.selectProject(_projectId);
        setState(() {
          _projectName = controller.selectedProjectName.value ?? _projectName;
        });
        _applySavedStepperState();
        _hydrateRemoteStepperState();
      });
    }

    _setupFormListeners();

    // Watch for ID migration (local -> firestore)
    ever(controller.selectedProjectId, (newId) {
      if (newId != null && newId.isNotEmpty && newId != _projectId) {
        if (_projectId?.startsWith('local_') ?? false) {
          debugPrint(
            'ProjectStepperPage: Migrating local ID $_projectId to $newId',
          );
          setState(() {
            _projectId = newId;
          });
        }
      }
    });
  }

  void _applySavedStepperState() {
    if (_projectId == null || _projectId!.isEmpty) return;

    final savedBoxes = controller.projectBoxValues[_projectId!];
    if (savedBoxes != null) {
      sampleDocController.boxHeaviestController.text =
          savedBoxes['heaviest'] ?? '';
      sampleDocController.boxAverageController.text =
          savedBoxes['average'] ?? '';
      sampleDocController.boxLightestController.text =
          savedBoxes['lightest'] ?? '';
    }

    final savedWeights = controller.projectSampleWeights[_projectId!];
    if (savedWeights != null) {
      sampleDocController.docWeights.assignAll(savedWeights);
    }

    final savedGroups = controller.projectSampleGroups[_projectId!];
    if (savedGroups != null) {
      sampleDocController.setSampleGroups(savedGroups);
    }

    final savedSampleGroupBluetoothFlags =
        controller.projectSampleGroupBluetoothFlags[_projectId!];
    if (savedSampleGroupBluetoothFlags != null) {
      sampleDocController.setSampleGroupBluetoothFlags(
        savedSampleGroupBluetoothFlags,
      );
    }

    final savedDistributions = controller.projectDocDistributions[_projectId!];
    if (savedDistributions != null) {
      sampleDocController.setDocDistributions(savedDistributions);
    }

    final savedAttachmentUrls = controller.projectAttachmentUrls[_projectId!];
    if (savedAttachmentUrls != null) {
      // Protection: don't overwrite local photos with empty list if UI already has photos
      if (savedAttachmentUrls.isNotEmpty ||
          sampleDocController.attachmentUrls.isEmpty) {
        sampleDocController.setAttachmentUrls(savedAttachmentUrls);
      } else {
        debugPrint(
          'ProjectStepperPage: Preserving local photos (prevented empty override from controller)',
        );
      }
    }

    final savedBluetoothInput = controller.projectBluetoothInputs[_projectId!];
    if (savedBluetoothInput != null) {
      sampleDocController.setSampleInputBluetooth(savedBluetoothInput);
      sampleDocController.setDistributionBluetooth(savedBluetoothInput);
    }

    final savedSampleBluetooth =
        controller.projectSampleBluetoothInputs[_projectId!];
    if (savedSampleBluetooth != null) {
      sampleDocController.setSampleInputBluetooth(savedSampleBluetooth);
    }

    final savedDistributionBluetooth =
        controller.projectDistributionBluetoothInputs[_projectId!];
    if (savedDistributionBluetooth != null) {
      sampleDocController.setDistributionBluetooth(savedDistributionBluetooth);
    }

    final savedPens = controller.projectDietPenSelections[_projectId!];
    if (savedPens != null) {
      dietMappingController.dietPenSelections.assignAll(savedPens);
    }

    final savedDietInputs = controller.projectDietInputValues[_projectId!];
    if (savedDietInputs != null) {
      dietMappingController.loadDietInputValues(savedDietInputs);
    }
  }

  Future<void> _hydrateRemoteStepperState() async {
    if (_projectId == null || _projectId!.isEmpty) return;
    await controller.hydrateStepperDataFromFirestore(_projectId!);
    if (!mounted) return;
    _applySavedStepperState();
    setState(() {});
  }

  void _setupFormListeners() {
    // Listen to all TextEditingControllers
    controller.projectNameController.addListener(_triggerRebuild);
    controller.trialDateController.addListener(_triggerRebuild);
    controller.docWeightController.addListener(_triggerRebuild);
    controller.docInDateController.addListener(_triggerRebuild);
    controller.trialHouseController.addListener(_triggerRebuild);
    controller.dietController.addListener(_triggerRebuild);
    controller.replicationController.addListener(_triggerRebuild);
    sampleDocController.boxHeaviestController.addListener(_triggerRebuild);
    sampleDocController.boxAverageController.addListener(_triggerRebuild);
    sampleDocController.boxLightestController.addListener(_triggerRebuild);

    // Register callbacks for observable changes
    dietMappingController.addChangeListener(_triggerRebuild);
    sampleDocController.addChangeListener(_triggerRebuild);
  }

  void _triggerRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Remove all listeners
    controller.projectNameController.removeListener(_triggerRebuild);
    controller.trialDateController.removeListener(_triggerRebuild);
    controller.docWeightController.removeListener(_triggerRebuild);
    controller.docInDateController.removeListener(_triggerRebuild);
    controller.trialHouseController.removeListener(_triggerRebuild);
    controller.dietController.removeListener(_triggerRebuild);
    controller.replicationController.removeListener(_triggerRebuild);
    sampleDocController.boxHeaviestController.removeListener(_triggerRebuild);
    sampleDocController.boxAverageController.removeListener(_triggerRebuild);
    sampleDocController.boxLightestController.removeListener(_triggerRebuild);

    if (Get.isRegistered<SampleDocController>()) {
      Get.delete<SampleDocController>();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int step) async {
    if (!_isReadOnly) {
      await _persistCurrentProjectProgress();
    }

    setState(() {
      _currentStep = step;
    });

    if (_projectId != null && _projectId!.isNotEmpty) {
      controller.updateLastOpenedStep(_projectId!, _currentStep);
    }

    // If going to the Sample Doc step (index 2), ensure the controller is up to date
    if (step == 2 && _projectId != null) {
      _applySavedStepperState();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        if (_isUploadingAttachments) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for photo upload to finish'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }

        // Ensure current data is persisted before popping
        _persistCurrentProjectProgress().then((_) {
          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF111827)),
          shape: const Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          title: Text(
            (_projectName != null && _projectName!.trim().isNotEmpty)
                ? _projectName!
                : 'Project',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            if (_projectId != null &&
                (controller.statusFor(_projectId!) ==
                        BroilerWorkflowStatus.inProgress ||
                    controller.statusFor(_projectId!) ==
                        BroilerWorkflowStatus.completed))
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  onPressed: () async {
                    if (_projectId == null || _projectId!.isEmpty) return;
                    final project = controller.projects.firstWhereOrNull(
                      (p) => p.projectId == _projectId,
                    );
                    if (project == null) return;

                    Get.to(() => PdfPreviewPage(
                      project: project,
                      sampleWeights: sampleDocController.docWeights,
                      sampleGroups: sampleDocController.sampleGroups,
                      sampleGroupBluetoothFlags: sampleDocController.sampleGroupBluetoothFlags,
                      docDistributions: sampleDocController.docDistributions,
                      attachmentUrls: sampleDocController.attachmentUrls,
                      boxValues: {
                        'heaviest': sampleDocController.boxHeaviestController.text,
                        'average': sampleDocController.boxAverageController.text,
                        'lightest': sampleDocController.boxLightestController.text,
                      },
                      dietPens: dietMappingController.dietPenSelections,
                      dietInputs: dietMappingController.dietInputValues,
                    ));
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFF111827),
                  ),
                  tooltip: 'Export PDF',
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AbsorbPointer(
                        absorbing: _isReadOnly && _currentStep != 2,
                        child: _buildCurrentStepContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    // final finalButtonLabel = _openedFromDraft ? 'Update Project' : 'Finish';
    // final isStepTwoLocked = _currentStep == 1 && !_canProceedFromDietMapping();

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: _currentStep == 0
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isReadOnly) {
                      _goToStep(1);
                      return;
                    }

                    setState(() {
                      _showProjectInfoValidation = true;
                    });
                    final isFormValid =
                        _projectInfoFormKey.currentState?.validate() ?? false;
                    if (!isFormValid) {
                      return;
                    }

                    final isSaved = await controller.saveProject();
                    if (isSaved) {
                      _projectId = controller.selectedProjectId.value;
                      _projectName = controller.projectNameController.text
                          .trim();
                      if (_projectId != null && _projectId!.isNotEmpty) {
                        await controller.markDrafted(_projectId!, step: 1);
                      }
                      await _persistCurrentProjectProgress();
                      await _goToStep(1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isUploadingAttachments
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please wait for photo upload to finish',
                                    ),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                              }
                            : () async {
                                if (!_isReadOnly) {
                                  await _persistCurrentProjectProgress();
                                }
                                await _goToStep(_currentStep - 1);
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                          side: const BorderSide(color: Color(0xFF22C55E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                    flex: 3,
                    child: SizedBox(
                      height: 50,
                      child: _buildNextFinishButton(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNextFinishButton() {
    return Obx(() {
      final isStepTwoLocked =
          _currentStep == 1 && !_canProceedFromDietMapping();
      final isInProgress = _projectId != null &&
          controller.statusFor(_projectId!) == BroilerWorkflowStatus.inProgress;

      // Step 3 read-only (inProgress) and all monitoring complete → show Completed button
      if (_currentStep == 2 && isInProgress && _allMonitoringComplete()) {
        return ElevatedButton(
          onPressed: _isUploadingAttachments
              ? null
              : () async {
                  await controller.markCompleted(_projectId!);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project marked as completed!'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                  // Pastikan navigasi dilakukan setelah frame selesai
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) Get.back();
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 20),
              SizedBox(width: 8),
              Text(
                'Completed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      }

      // Default next/finish button
      final finalButtonLabel = _openedFromDraft ? 'Update Project' : 'Finish';
      return ElevatedButton(
        onPressed: isStepTwoLocked
            ? null
            : (_currentStep == 2 && (_isReadOnly || !_canFinishProject()))
                ? null
                : _isUploadingAttachments
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please wait for photo upload to finish',
                            ),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      }
                    : () async {
                        if (!_isReadOnly) {
                          final isSaved =
                              await _persistCurrentProjectProgress();
                          if (!isSaved) return;
                        }
                        if (_currentStep < 2) {
                          if (_isReadOnly) {
                            _goToStep(_currentStep + 1);
                            return;
                          }
                          if (_projectId != null && _projectId!.isNotEmpty) {
                            await controller.markDrafted(
                              _projectId!,
                              step: _currentStep + 1,
                            );
                          }
                          await _persistCurrentProjectProgress();
                          await _goToStep(_currentStep + 1);
                        } else {
                          if (_projectId == null || _projectId!.isEmpty) {
                            final isSaved = await controller.saveProject();
                            if (!isSaved) return;
                            _projectId = controller.selectedProjectId.value;
                            _projectName =
                                controller.projectNameController.text.trim();
                          }
                          await _persistCurrentProjectProgress();
                          Future.microtask(() async {
                            await controller.markInProgress(_projectId!);
                          });
                          if (!mounted) return;
                          setState(() {
                            _isReadOnly = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Project finalized successfully',
                              ),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                          Get.back();
                        }
                      },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          disabledBackgroundColor: const Color(0xFFBDBDBD),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _currentStep < 2 ? 'Next' : finalButtonLabel,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    });
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return BroilerProjectInformationSection(
          controller: controller,
          formKey: _projectInfoFormKey,
          showValidation: _showProjectInfoValidation,
        );
      case 1:
        return DietPenMappingSection(controller: dietMappingController);
      case 2:
        return SampleDocSection(
          readOnly: _isReadOnly,
          boxHeaviestController: sampleDocController.boxHeaviestController,
          boxAverageController: sampleDocController.boxAverageController,
          boxLightestController: sampleDocController.boxLightestController,
          docWeights: List<double>.from(sampleDocController.docWeights),
          onDocWeightsChanged: (weights) {
            sampleDocController.docWeights.assignAll(weights);
          },
          sampleGroups: List<List<double>>.from(
            sampleDocController.sampleGroups.map((e) => List<double>.from(e)),
          ),
          onSampleGroupsChanged: (groups) {
            sampleDocController.setSampleGroups(groups);
            if (mounted) {
              setState(() {});
            }
          },
          sampleBluetoothFlags: List<List<bool>>.from(
            sampleDocController.sampleGroupBluetoothFlags.map(
              (e) => List<bool>.from(e),
            ),
          ),
          onSampleBluetoothFlagsChanged: (flags) {
            sampleDocController.setSampleGroupBluetoothFlags(flags);
            if (mounted) {
              setState(() {});
            }
          },
          docDistributions: List<Map<String, dynamic>>.from(
            sampleDocController.docDistributions.map(
              (e) => Map<String, dynamic>.from(e),
            ),
          ),
          onDocDistributionsChanged: (distributions) {
            sampleDocController.setDocDistributions(distributions);
            if (mounted) {
              setState(() {});
            }
          },
          initialAttachmentUrls: List<String>.from(
            sampleDocController.attachmentUrls,
          ),
          projectId: _projectId,
          onAttachmentUrlsChanged: (urls) {
            sampleDocController.setAttachmentUrls(urls);
            if (mounted) {
              setState(() {});
              _persistCurrentProjectProgress();
            }
          },
          sampleInputBluetooth: sampleDocController.sampleInputBluetooth.value,
          onSampleInputBluetoothChanged: (value) {
            sampleDocController.setSampleInputBluetooth(value);
            if (mounted) {
              setState(() {});
            }
          },
          distributionBluetooth:
              sampleDocController.distributionBluetooth.value,
          onDistributionBluetoothChanged: (value) {
            sampleDocController.setDistributionBluetooth(value);
            if (mounted) {
              setState(() {});
            }
          },
          dietReplication: dietMappingController.dietReplication.value ?? 1,
          totalPens: sampleDocController.totalPens.value,
          onUploadingStatusChanged: (isUploading) {
            setState(() => _isUploadingAttachments = isUploading);
          },
        );
      default:
        return BroilerProjectInformationSection(
          controller: controller,
          formKey: _projectInfoFormKey,
          showValidation: _showProjectInfoValidation,
        );
    }
  }

  bool _canFinishProject() {
    final validDistributionPens = <int>{};
    for (final item in sampleDocController.docDistributions) {
      final rawPen = item['pen'];
      final rawValue = item['valueKg'] ?? item['value'] ?? item['kg'];

      final pen = rawPen is int ? rawPen : int.tryParse('$rawPen');
      final value = rawValue is num
          ? rawValue.toDouble()
          : double.tryParse('$rawValue') ?? 0;

      if (pen != null && pen >= 1 && pen <= 42 && value > 0) {
        validDistributionPens.add(pen);
      }
    }

    final hasDocDistributionData = validDistributionPens.isNotEmpty;

    final hasSampleData =
        sampleDocController.boxHeaviestController.text.trim().isNotEmpty &&
        sampleDocController.boxAverageController.text.trim().isNotEmpty &&
        sampleDocController.boxLightestController.text.trim().isNotEmpty &&
        sampleDocController.sampleGroups.length >= 3 &&
        sampleDocController.sampleGroups.every((group) => group.isNotEmpty) &&
        hasDocDistributionData;

    return hasSampleData;
  }

  bool _allMonitoringComplete() {
    if (_projectId == null || _projectId!.isEmpty) return false;

    final infeedController = Get.isRegistered<InfeedController>()
        ? Get.find<InfeedController>()
        : Get.put(InfeedController());
    final mortalityController = Get.isRegistered<MortalityController>()
        ? Get.find<MortalityController>()
        : Get.put(MortalityController());
    final weighingController = Get.isRegistered<WeighingController>()
        ? Get.find<WeighingController>()
        : Get.put(WeighingController());
    final maleBirdsController = Get.isRegistered<MaleBirdsController>()
        ? Get.find<MaleBirdsController>()
        : Get.put(MaleBirdsController());
    final fesesController = Get.isRegistered<FesesController>()
        ? Get.find<FesesController>()
        : Get.put(FesesController());

    final hasInfeed = infeedController.infeedList.isNotEmpty;
    final hasDepletion = mortalityController.entries.isNotEmpty;
    final hasWeighing = weighingController.weighingHistory.isNotEmpty;
    final hasMaleBirds = maleBirdsController.entries.isNotEmpty;
    final hasFeses = fesesController.entries.isNotEmpty;

    return hasInfeed && hasDepletion && hasWeighing && hasMaleBirds && hasFeses;
  }

  bool _canProceedFromDietMapping() {
    final expectedDietCount = int.tryParse(controller.dietController.text) ?? 0;
    if (expectedDietCount <= 0) return false;

    final scopedEntries = dietMappingController.dietPenSelections.entries
        .where((entry) => entry.key <= expectedDietCount)
        .toList();

    final allDietHasPens =
        scopedEntries.length >= expectedDietCount &&
        scopedEntries.every((entry) => entry.value.isNotEmpty);

    if (!allDietHasPens) return false;

    final hasDietInputs = List.generate(expectedDietCount, (index) => index + 1)
        .every((diet) {
          final values =
              dietMappingController.dietInputValues[diet] ??
              const <String, String>{};
          return (values['preStarter'] ?? '').trim().isNotEmpty &&
              (values['starter'] ?? '').trim().isNotEmpty &&
              (values['finisher'] ?? '').trim().isNotEmpty;
        });

    if (!hasDietInputs) return false;

    final uniquePens = <int>{};
    for (final entry in scopedEntries) {
      uniquePens.addAll(entry.value.where((pen) => pen >= 1 && pen <= 42));
    }

    return uniquePens.length == 42;
  }

  Future<bool> _persistCurrentProjectProgress() async {
    if (_projectId == null || _projectId!.isEmpty) return false;

    controller.updateLastOpenedStep(_projectId!, _currentStep);
    return await controller.saveStepperData(
      projectId: _projectId!,
      sampleWeights: sampleDocController.docWeights,
      sampleGroups: sampleDocController.sampleGroups,
      sampleBluetoothFlags: sampleDocController.sampleGroupBluetoothFlags,
      docDistributions: sampleDocController.docDistributions,
      attachmentUrls: sampleDocController.attachmentUrls,
      sampleInputBluetooth: sampleDocController.sampleInputBluetooth.value,
      distributionBluetooth: sampleDocController.distributionBluetooth.value,
      boxHeaviest: sampleDocController.boxHeaviestController.text,
      boxAverage: sampleDocController.boxAverageController.text,
      boxLightest: sampleDocController.boxLightestController.text,
      dietPens: {
        for (final entry in dietMappingController.dietPenSelections.entries)
          entry.key: List<int>.from(entry.value),
      },
      dietInputs: {
        for (final entry in dietMappingController.dietInputValues.entries)
          entry.key: Map<String, String>.from(entry.value),
      },
    );
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
