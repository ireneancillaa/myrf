import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'diet_mapping_controller.dart';
import '../models/broiler_project_data.dart';
import '../services/broiler_firestore_service.dart';

enum BroilerWorkflowStatus { drafted, inProgress }

class BroilerController extends GetxController {
  final projectNameController = TextEditingController();
  final trialDateController = TextEditingController();
  final trialHouseController = TextEditingController();
  final strainController = TextEditingController();
  final hatcheryController = TextEditingController();
  final breedingFarmController = TextEditingController();
  final boxBatchCodeController = TextEditingController();
  final selectorController = TextEditingController();
  final docInDateController = TextEditingController();
  final docWeightController = TextEditingController();
  final weighing3WeeksController = TextEditingController();
  final weighing5WeeksController = TextEditingController();
  final numberOfBirdsController = TextEditingController();
  final dietController = TextEditingController();
  final replicationController = TextEditingController();

  final projects = <BroilerProjectData>[].obs;
  final selectedProjectId = RxnString();
  final selectedProjectName = RxnString();
  final selectedTrialHouse = RxnString();
  final selectedStrain = RxnString();
  final selectedHatchery = RxnString();
  final selectedDocInDate = RxnString();
  final projectStatuses = <String, BroilerWorkflowStatus>{}.obs;
  final projectLastOpenedSteps = <String, int>{}.obs;
  final projectSampleWeights = <String, List<double>>{}.obs;
  final projectSampleGroups = <String, List<List<double>>>{}.obs;
  final projectSampleGroupBluetoothFlags = <String, List<List<bool>>>{}.obs;
  final projectDocDistributions = <String, List<Map<String, dynamic>>>{}.obs;
  final projectAttachmentUrls = <String, List<String>>{}.obs;
  final projectBluetoothInputs = <String, bool>{}.obs;
  final projectSampleBluetoothInputs = <String, bool>{}.obs;
  final projectDistributionBluetoothInputs = <String, bool>{}.obs;
  final projectBoxValues = <String, Map<String, String>>{}.obs;
  final projectDietPenSelections = <String, Map<int, List<int>>>{}.obs;
  final projectDietInputValues = <String, Map<int, Map<String, String>>>{}.obs;

  VoidCallback? _onStatusChangeCallback;
  late final BroilerFirestoreService _firestoreService;
  StreamSubscription<Map<String, String>>? _statusSubscription;
  StreamSubscription<List<BroilerProjectData>>? _projectsSubscription;
  final Map<String, Future<void>> _projectSyncQueue = <String, Future<void>>{};

  @override
  void onInit() {
    super.onInit();
    _firestoreService = Get.isRegistered<BroilerFirestoreService>()
        ? Get.find<BroilerFirestoreService>()
        : Get.put(BroilerFirestoreService(), permanent: true);

    _bindFirestoreStreams();
  }

  List<String> get projectNames =>
      projects.map((item) => item.projectName).toList();

  List<String> get inProgressProjectNames {
    return projects
        .where(
          (item) =>
              statusFor(item.projectId) == BroilerWorkflowStatus.inProgress,
        )
        .map((item) => item.projectName)
        .toList();
  }

  void selectProject(String? projectId) {
    if (projectId == null) return;
    final project = projects.firstWhereOrNull(
      (item) => item.projectId == projectId,
    );
    if (project == null) return;

    selectedProjectId.value = project.projectId;
    selectedProjectName.value = project.projectName;
    projectNameController.text = project.projectName;
    trialDateController.text = project.trialDate;
    trialHouseController.text = project.trialHouse;
    strainController.text = project.strain;
    hatcheryController.text = project.hatchery;
    breedingFarmController.text = project.breedingFarm;
    boxBatchCodeController.text = project.boxBatchCode;
    selectorController.text = project.selector;
    docInDateController.text = project.docInDate;
    docWeightController.text = project.docWeight;
    weighing3WeeksController.text = project.weighing3Weeks;
    weighing5WeeksController.text = project.weighing5Weeks;
    numberOfBirdsController.text = project.numberOfBirds;
    dietController.text = project.diet;
    replicationController.text = project.replication;
    selectedTrialHouse.value = project.trialHouse;
    selectedStrain.value = project.strain;
    selectedHatchery.value = project.hatchery;
    selectedDocInDate.value = project.docInDate;

    final dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
    dietMappingController.syncFromValues(
      diet: project.diet,
      replication: project.replication,
    );
  }

  void selectProjectByName(String? projectName) {
    if (projectName == null) return;
    final project = projects.firstWhereOrNull(
      (item) => item.projectName == projectName,
    );
    if (project == null) return;
    selectProject(project.projectId);
  }

  BroilerWorkflowStatus statusFor(String projectId) {
    return projectStatuses[projectId] ?? BroilerWorkflowStatus.drafted;
  }

  bool hasDuplicateDraftedProjectName({
    required String projectName,
    String? excludeProjectId,
  }) {
    final normalizedName = projectName.trim().toLowerCase();
    if (normalizedName.isEmpty) return false;

    final normalizedExcludeId = excludeProjectId?.trim() ?? '';
    for (final project in projects) {
      if (normalizedExcludeId.isNotEmpty &&
          project.projectId == normalizedExcludeId) {
        continue;
      }

      final isDrafted =
          statusFor(project.projectId) == BroilerWorkflowStatus.drafted;
      if (!isDrafted) continue;

      if (project.projectName.trim().toLowerCase() == normalizedName) {
        return true;
      }
    }

    return false;
  }

  void addStatusChangeListener(VoidCallback callback) {
    _onStatusChangeCallback = callback;
  }

  void _notifyStatusChange() {
    _onStatusChangeCallback?.call();
  }

  int lastOpenedStepFor(String projectId) {
    return projectLastOpenedSteps[projectId] ?? 0;
  }

  bool isReadOnly(String projectId) {
    return statusFor(projectId) == BroilerWorkflowStatus.inProgress;
  }

  BroilerWorkflowStatus _statusFromFirestore(String value) {
    return value.trim().toLowerCase() == 'in_progress'
        ? BroilerWorkflowStatus.inProgress
        : BroilerWorkflowStatus.drafted;
  }

  String _statusToFirestore(BroilerWorkflowStatus status) {
    return status == BroilerWorkflowStatus.inProgress
        ? 'in_progress'
        : 'drafted';
  }

  void _bindFirestoreStreams() {
    _statusSubscription?.cancel();
    _projectsSubscription?.cancel();

    _projectsSubscription = _firestoreService.watchProjects().listen((
      remoteProjects,
    ) {
      projects.assignAll(remoteProjects);
    });

    _statusSubscription = _firestoreService.watchProjectStatuses().listen((
      remoteStatuses,
    ) {
      final mapped = <String, BroilerWorkflowStatus>{
        for (final entry in remoteStatuses.entries)
          entry.key: _statusFromFirestore(entry.value),
      };
      projectStatuses.assignAll(mapped);
    });
  }

  String _createLocalProjectId() {
    return 'local_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _enqueueProjectSync(String projectId, {bool showErrorSnackbar = true}) {
    final queueKey = projectId.trim();
    if (queueKey.isEmpty) return;

    final previousSync = _projectSyncQueue[queueKey] ?? Future<void>.value();
    final nextSync = previousSync.then((_) async {
      final saved = await _syncProjectToFirestore(queueKey);
      if (!saved && showErrorSnackbar) {
        Get.snackbar('Sync Failed', 'Data could not be synced to Firebase');
      }
    });

    _projectSyncQueue[queueKey] = nextSync;
    unawaited(
      nextSync.whenComplete(() {
        if (identical(_projectSyncQueue[queueKey], nextSync)) {
          _projectSyncQueue.remove(queueKey);
        }
      }),
    );
  }

  Future<bool> _syncProjectToFirestore(String projectId) async {
    final data = projects.firstWhereOrNull(
      (item) => item.projectId == projectId,
    );
    if (data == null) return false;

    try {
      final savedProjectId = await _firestoreService.upsertProjectRecord(
        projectId: data.projectId,
        data: data,
        status: _statusToFirestore(statusFor(data.projectId)),
        sampleWeights: List<double>.from(
          projectSampleWeights[data.projectId] ?? const <double>[],
        ),
        sampleGroups: List<List<double>>.generate(3, (index) {
          final groups =
              projectSampleGroups[data.projectId] ?? const <List<double>>[];
          return index < groups.length
              ? List<double>.from(groups[index])
              : <double>[];
        }),
        sampleGroupBluetoothFlags: List<List<bool>>.generate(3, (index) {
          final flags =
              projectSampleGroupBluetoothFlags[data.projectId] ??
              const <List<bool>>[];
          return index < flags.length
              ? List<bool>.from(flags[index])
              : <bool>[];
        }),
        docDistributions: List<Map<String, dynamic>>.from(
          projectDocDistributions[data.projectId] ??
              const <Map<String, dynamic>>[],
        ),
        attachmentUrls: List<String>.from(
          projectAttachmentUrls[data.projectId] ?? const <String>[],
        ),
        sampleInputBluetooth:
            projectSampleBluetoothInputs[data.projectId] ?? false,
        distributionBluetooth:
            projectDistributionBluetoothInputs[data.projectId] ?? false,
        boxHeaviest: (projectBoxValues[data.projectId]?['heaviest'] ?? ''),
        boxAverage: (projectBoxValues[data.projectId]?['average'] ?? ''),
        boxLightest: (projectBoxValues[data.projectId]?['lightest'] ?? ''),
        dietPens: {
          for (final entry
              in (projectDietPenSelections[data.projectId] ??
                      const <int, List<int>>{})
                  .entries)
            entry.key: List<int>.from(entry.value),
        },
        dietInputs: {
          for (final entry
              in (projectDietInputValues[data.projectId] ??
                      const <int, Map<String, String>>{})
                  .entries)
            entry.key: Map<String, String>.from(entry.value),
        },
      );

      if (savedProjectId != data.projectId) {
        final index = projects.indexWhere(
          (item) => item.projectId == projectId,
        );
        if (index >= 0) {
          projects[index] = data.copyWith(projectId: savedProjectId);
          projects.refresh();
        }

        projectStatuses[savedProjectId] =
            projectStatuses.remove(projectId) ?? BroilerWorkflowStatus.drafted;
        projectLastOpenedSteps[savedProjectId] =
            projectLastOpenedSteps.remove(projectId) ?? 0;
        projectSampleWeights[savedProjectId] =
            projectSampleWeights.remove(projectId) ?? const <double>[];
        projectSampleGroups[savedProjectId] =
            projectSampleGroups.remove(projectId) ??
            const <List<double>>[<double>[], <double>[], <double>[]];
        projectSampleGroupBluetoothFlags[savedProjectId] =
            projectSampleGroupBluetoothFlags.remove(projectId) ??
            const <List<bool>>[<bool>[], <bool>[], <bool>[]];
        projectDocDistributions[savedProjectId] =
            projectDocDistributions.remove(projectId) ??
            const <Map<String, dynamic>>[];
        projectAttachmentUrls[savedProjectId] =
            projectAttachmentUrls.remove(projectId) ?? const <String>[];
        projectBoxValues[savedProjectId] =
            projectBoxValues.remove(projectId) ??
            const <String, String>{
              'heaviest': '',
              'average': '',
              'lightest': '',
            };
        projectBluetoothInputs[savedProjectId] =
            projectBluetoothInputs.remove(projectId) ?? false;
        projectSampleBluetoothInputs[savedProjectId] =
            projectSampleBluetoothInputs.remove(projectId) ?? false;
        projectDistributionBluetoothInputs[savedProjectId] =
            projectDistributionBluetoothInputs.remove(projectId) ?? false;
        projectDietPenSelections[savedProjectId] =
            projectDietPenSelections.remove(projectId) ??
            const <int, List<int>>{};
        projectDietInputValues[savedProjectId] =
            projectDietInputValues.remove(projectId) ??
            const <int, Map<String, String>>{};

        if (selectedProjectId.value == projectId ||
            (selectedProjectId.value == null && projectId.isEmpty)) {
          selectedProjectId.value = savedProjectId;
        }
      }

      return true;
    } catch (error) {
      debugPrint('Firestore sync failed for $projectId: $error');
      return false;
    }
  }

  Map<int, List<int>> _parseDietPens(dynamic raw) {
    if (raw is! Map) return <int, List<int>>{};
    final parsed = <int, List<int>>{};
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      if (key == null) continue;
      final value = entry.value;
      if (value is! List) continue;
      parsed[key] =
          value
              .map((item) => item is int ? item : int.tryParse('$item'))
              .whereType<int>()
              .toList()
            ..sort();
    }
    return parsed;
  }

  Map<int, Map<String, String>> _parseDietInputs(dynamic raw) {
    if (raw is! Map) return <int, Map<String, String>>{};
    final parsed = <int, Map<String, String>>{};
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      if (key == null || entry.value is! Map) continue;
      final item = Map<String, dynamic>.from(entry.value as Map);
      parsed[key] = {
        'preStarter': (item['preStarter'] ?? '').toString(),
        'starter': (item['starter'] ?? '').toString(),
        'finisher': (item['finisher'] ?? '').toString(),
        'remarks': (item['remarks'] ?? '').toString(),
      };
    }
    return parsed;
  }

  List<double> _parseSampleWeights(dynamic raw) {
    if (raw is! List) return const <double>[];
    return raw
        .map((item) => item is num ? item.toDouble() : double.tryParse('$item'))
        .whereType<double>()
        .toList();
  }

  List<List<double>> _parseSampleGroups(dynamic raw) {
    if (raw is! Map) {
      return const <List<double>>[<double>[], <double>[], <double>[]];
    }
    return List<List<double>>.generate(3, (index) {
      final listRaw = raw['$index'];
      if (listRaw is! List) return <double>[];
      return listRaw
          .map(
            (item) => item is num ? item.toDouble() : double.tryParse('$item'),
          )
          .whereType<double>()
          .toList();
    });
  }

  List<List<bool>> _parseSampleGroupBluetoothFlags(
    dynamic raw,
    List<List<double>> sampleGroups,
  ) {
    if (raw is! Map) {
      return List<List<bool>>.generate(
        3,
        (index) => List<bool>.filled(
          index < sampleGroups.length ? sampleGroups[index].length : 0,
          false,
        ),
      );
    }

    return List<List<bool>>.generate(3, (index) {
      final listRaw = raw['$index'];
      final valuesLength = index < sampleGroups.length
          ? sampleGroups[index].length
          : 0;
      if (listRaw is! List) {
        return List<bool>.filled(valuesLength, false);
      }

      final parsed = listRaw.map((item) {
        if (item is bool) return item;
        final text = '$item'.trim().toLowerCase();
        return text == 'yes' || text == 'true';
      }).toList();

      if (parsed.length < valuesLength) {
        parsed.addAll(List<bool>.filled(valuesLength - parsed.length, false));
      } else if (parsed.length > valuesLength) {
        parsed.removeRange(valuesLength, parsed.length);
      }
      return parsed;
    });
  }

  List<Map<String, dynamic>> _parseDocDistributions(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _parseAttachmentUrls(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> hydrateStepperDataFromFirestore(String projectId) async {
    try {
      final record = await _firestoreService.getProjectRecord(
        projectId: projectId,
      );
      if (record == null) return;

      final sampleWeights = _parseSampleWeights(record['sample_weights']);
      final sampleGroups = _parseSampleGroups(record['sample_groups']);
      final sampleGroupBluetoothFlags = _parseSampleGroupBluetoothFlags(
        record['sample_groups_bluetooth'],
        sampleGroups,
      );
      final docDistributions = _parseDocDistributions(
        record['doc_distributions'],
      );
      final attachmentUrls = _parseAttachmentUrls(record['attachment_urls']);
      final dietPens = _parseDietPens(record['diet_pen_selections']);
      final dietInputs = _parseDietInputs(record['diet_input_values']);

      projectSampleWeights[projectId] = sampleWeights;
      projectSampleGroups[projectId] = sampleGroups;
      projectSampleGroupBluetoothFlags[projectId] = sampleGroupBluetoothFlags;
      projectDocDistributions[projectId] = docDistributions;
      projectAttachmentUrls[projectId] = attachmentUrls;
      projectBoxValues[projectId] = {
        'heaviest': (record['box_heaviest'] ?? '').toString(),
        'average': (record['box_average'] ?? '').toString(),
        'lightest': (record['box_lightest'] ?? '').toString(),
      };
      final rawBluetooth = (record['is_bluetooth'] ?? '').toString();
      projectBluetoothInputs[projectId] =
          rawBluetooth.trim().toLowerCase() == 'yes';
      final rawSampleBluetooth =
          (record['sample_is_bluetooth'] ?? record['is_bluetooth'] ?? '')
              .toString();
      projectSampleBluetoothInputs[projectId] =
          rawSampleBluetooth.trim().toLowerCase() == 'yes';
      final rawDistributionBluetooth =
          (record['distribution_is_bluetooth'] ?? record['is_bluetooth'] ?? '')
              .toString();
      projectDistributionBluetoothInputs[projectId] =
          rawDistributionBluetooth.trim().toLowerCase() == 'yes';
      projectDietPenSelections[projectId] = dietPens;
      projectDietInputValues[projectId] = dietInputs;

      final dietMappingController = Get.isRegistered<DietMappingController>()
          ? Get.find<DietMappingController>()
          : Get.put(DietMappingController(), permanent: true);

      if (selectedProjectId.value == projectId) {
        dietMappingController.dietPenSelections.assignAll(dietPens);
        dietMappingController.loadDietInputValues(dietInputs);
        if ((dietController.text.trim().isNotEmpty) &&
            (replicationController.text.trim().isNotEmpty)) {
          dietMappingController.syncFromValues(
            diet: dietController.text,
            replication: replicationController.text,
          );
        }
      }
    } catch (error) {
      debugPrint('Failed to hydrate stepper data for $projectId: $error');
    }
  }

  Future<void> markDrafted(String projectId, {int step = 1}) {
    projectStatuses[projectId] = BroilerWorkflowStatus.drafted;
    projectStatuses.refresh();
    updateLastOpenedStep(projectId, step);
    _enqueueProjectSync(projectId);
    return Future<void>.value();
  }

  Future<void> markInProgress(String projectId) {
    projectStatuses[projectId] = BroilerWorkflowStatus.inProgress;
    projectStatuses.refresh();
    projects.refresh();
    _notifyStatusChange();
    updateLastOpenedStep(projectId, 2);
    _enqueueProjectSync(projectId);
    return Future<void>.value();
  }

  void updateLastOpenedStep(String projectId, int step) {
    projectLastOpenedSteps[projectId] = step.clamp(0, 2);
  }

  Future<bool> saveStepperData({
    required String projectId,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
    required List<List<bool>> sampleBluetoothFlags,
    required List<Map<String, dynamic>> docDistributions,
    required List<String> attachmentUrls,
    required bool sampleInputBluetooth,
    required bool distributionBluetooth,
    required String boxHeaviest,
    required String boxAverage,
    required String boxLightest,
    required Map<int, List<int>> dietPens,
    required Map<int, Map<String, String>> dietInputs,
  }) {
    projectSampleWeights[projectId] = List<double>.from(sampleWeights);
    projectSampleGroups[projectId] = List<List<double>>.generate(
      3,
      (index) => index < sampleGroups.length
          ? List<double>.from(sampleGroups[index])
          : <double>[],
    );
    projectSampleGroupBluetoothFlags[projectId] = List<List<bool>>.generate(
      3,
      (index) => index < sampleBluetoothFlags.length
          ? List<bool>.from(sampleBluetoothFlags[index])
          : <bool>[],
    );
    projectDocDistributions[projectId] = List<Map<String, dynamic>>.from(
      docDistributions,
    );
    projectAttachmentUrls[projectId] = attachmentUrls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    projectSampleBluetoothInputs[projectId] = sampleInputBluetooth;
    projectDistributionBluetoothInputs[projectId] = distributionBluetooth;
    projectBluetoothInputs[projectId] =
        sampleInputBluetooth || distributionBluetooth;
    projectBoxValues[projectId] = {
      'heaviest': boxHeaviest,
      'average': boxAverage,
      'lightest': boxLightest,
    };
    projectDietPenSelections[projectId] = {
      for (final entry in dietPens.entries)
        entry.key: List<int>.from(entry.value),
    };
    projectDietInputValues[projectId] = {
      for (final entry in dietInputs.entries)
        entry.key: Map<String, String>.from(entry.value),
    };

    _enqueueProjectSync(projectId);
    return Future<bool>.value(true);
  }

  void clearForm() {
    projectNameController.clear();
    trialDateController.clear();
    trialHouseController.clear();
    strainController.clear();
    hatcheryController.clear();
    breedingFarmController.clear();
    boxBatchCodeController.clear();
    selectorController.clear();
    docInDateController.clear();
    docWeightController.clear();
    weighing3WeeksController.clear();
    weighing5WeeksController.clear();
    numberOfBirdsController.clear();
    dietController.clear();
    replicationController.clear();

    selectedProjectId.value = null;
    selectedProjectName.value = null;
    selectedTrialHouse.value = null;
    selectedStrain.value = null;
    selectedHatchery.value = null;
    selectedDocInDate.value = null;
  }

  Future<bool> saveProject() async {
    final projectName = projectNameController.text.trim();
    final trialDate = trialDateController.text.trim();
    final docWeight = docWeightController.text.trim();
    final docInDate = docInDateController.text.trim();
    final trialHouse = trialHouseController.text.trim();
    final diet = dietController.text.trim();
    final replication = replicationController.text.trim();

    if (projectName.isEmpty) {
      Get.snackbar('Project Name / Chick Cycle', 'This field is required');
      return false;
    }
    if (trialDate.isEmpty) {
      Get.snackbar('Date Trial', 'This field is required');
      return false;
    }
    if (docWeight.isEmpty) {
      Get.snackbar('DOC Weight (Kg)', 'This field is required');
      return false;
    }
    if (docInDate.isEmpty) {
      Get.snackbar('DOC In', 'This field is required');
      return false;
    }
    if (trialHouse.isEmpty) {
      Get.snackbar('Map of Trial House', 'This field is required');
      return false;
    }
    if (diet.isEmpty) {
      Get.snackbar('Diet', 'This field is required');
      return false;
    }
    if (replication.isEmpty) {
      Get.snackbar('Replication', 'This field is required');
      return false;
    }

    final replicationNumber = (int.tryParse(replication) ?? 1).clamp(1, 9999);
    final selectedId = selectedProjectId.value?.trim() ?? '';
    final currentProjectId = selectedId.isNotEmpty
        ? selectedId
        : _createLocalProjectId();

    if (hasDuplicateDraftedProjectName(
      projectName: projectName,
      excludeProjectId: currentProjectId,
    )) {
      Get.defaultDialog(
        title: 'Duplicate Project Name',
        middleText:
            'Project name already exists in Drafted status. Use a different name.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF22C55E),
      );
      return false;
    }

    final data = BroilerProjectData(
      projectId: currentProjectId,
      projectName: projectName,
      trialDate: trialDate,
      trialHouse: trialHouse,
      strain: strainController.text.trim(),
      hatchery: hatcheryController.text.trim(),
      breedingFarm: breedingFarmController.text.trim(),
      boxBatchCode: boxBatchCodeController.text.trim(),
      selector: selectorController.text.trim(),
      docInDate: docInDate,
      docWeight: docWeight,
      weighing3Weeks: weighing3WeeksController.text.trim(),
      weighing5Weeks: weighing5WeeksController.text.trim(),
      numberOfBirds: numberOfBirdsController.text.trim(),
      diet: diet,
      replication: replication,
      dietReplication: replicationNumber,
    );

    final existingIndex = projects.indexWhere(
      (item) => item.projectId == currentProjectId,
    );
    if (existingIndex >= 0) {
      projects[existingIndex] = data;
    } else {
      projects.add(data);
    }

    final dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
    dietMappingController.syncFromValues(diet: diet, replication: replication);

    selectedProjectId.value = currentProjectId;
    selectedProjectName.value = projectName;
    _enqueueProjectSync(currentProjectId, showErrorSnackbar: true);
    Get.snackbar('Draft', 'Project saved to drafts');
    return true;
  }

  Future<bool> deleteDraftedProject(String projectId) async {
    if (statusFor(projectId) != BroilerWorkflowStatus.drafted) {
      return false;
    }

    try {
      await _firestoreService.deleteProjectRecord(projectId: projectId);
    } catch (error) {
      debugPrint('Failed to delete project $projectId: $error');
      Get.snackbar('Delete Failed', 'Project could not be deleted');
      return false;
    }

    projects.removeWhere((item) => item.projectId == projectId);
    projectStatuses.remove(projectId);
    projectLastOpenedSteps.remove(projectId);
    projectSampleWeights.remove(projectId);
    projectSampleGroups.remove(projectId);
    projectDocDistributions.remove(projectId);
    projectAttachmentUrls.remove(projectId);
    projectBoxValues.remove(projectId);
    projectDietPenSelections.remove(projectId);
    projectDietInputValues.remove(projectId);

    if (selectedProjectId.value == projectId) {
      clearForm();
    }

    Get.snackbar('Deleted', 'Draft project removed');
    return true;
  }

  @override
  void onClose() {
    _statusSubscription?.cancel();
    _projectsSubscription?.cancel();
    projectNameController.dispose();
    trialDateController.dispose();
    trialHouseController.dispose();
    strainController.dispose();
    hatcheryController.dispose();
    breedingFarmController.dispose();
    boxBatchCodeController.dispose();
    selectorController.dispose();
    docInDateController.dispose();
    docWeightController.dispose();
    weighing3WeeksController.dispose();
    weighing5WeeksController.dispose();
    numberOfBirdsController.dispose();
    dietController.dispose();
    replicationController.dispose();
    super.onClose();
  }
}
