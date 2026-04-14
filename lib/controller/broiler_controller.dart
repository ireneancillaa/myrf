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
  final selectedProjectName = RxnString();
  final selectedTrialHouse = RxnString();
  final selectedStrain = RxnString();
  final selectedHatchery = RxnString();
  final selectedDocInDate = RxnString();
  final projectStatuses = <String, BroilerWorkflowStatus>{}.obs;
  final projectLastOpenedSteps = <String, int>{}.obs;
  final projectSampleWeights = <String, List<double>>{}.obs;
  final projectSampleGroups = <String, List<List<double>>>{}.obs;
  final projectDocDistributions = <String, List<Map<String, dynamic>>>{}.obs;
  final projectBoxValues = <String, Map<String, String>>{}.obs;
  final projectDietPenSelections = <String, Map<int, List<int>>>{}.obs;
  final projectDietInputValues = <String, Map<int, Map<String, String>>>{}.obs;

  VoidCallback? _onStatusChangeCallback;
  late final BroilerFirestoreService _firestoreService;
  StreamSubscription<Map<String, String>>? _statusSubscription;
  StreamSubscription<List<BroilerProjectData>>? _projectsSubscription;

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
    final inProgressSet = projectStatuses.entries
        .where((entry) => entry.value == BroilerWorkflowStatus.inProgress)
        .map((entry) => entry.key)
        .toSet();

    return projects
        .where((item) => inProgressSet.contains(item.projectName))
        .map((item) => item.projectName)
        .toList();
  }

  void selectProject(String? projectName) {
    if (projectName == null) return;
    final project = projects.firstWhereOrNull(
      (item) => item.projectName == projectName,
    );
    if (project == null) return;

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

  BroilerWorkflowStatus statusFor(String projectName) {
    return projectStatuses[projectName] ?? BroilerWorkflowStatus.drafted;
  }

  void addStatusChangeListener(VoidCallback callback) {
    _onStatusChangeCallback = callback;
  }

  void _notifyStatusChange() {
    _onStatusChangeCallback?.call();
  }

  int lastOpenedStepFor(String projectName) {
    return projectLastOpenedSteps[projectName] ?? 0;
  }

  bool isReadOnly(String projectName) {
    return statusFor(projectName) == BroilerWorkflowStatus.inProgress;
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

  Future<bool> _syncProjectToFirestore(String projectName) async {
    final data = projects.firstWhereOrNull(
      (item) => item.projectName == projectName,
    );
    if (data == null) return false;

    try {
      await _firestoreService.upsertProjectRecord(
        data: data,
        status: _statusToFirestore(statusFor(projectName)),
        sampleWeights: List<double>.from(
          projectSampleWeights[projectName] ?? const <double>[],
        ),
        sampleGroups: List<List<double>>.generate(3, (index) {
          final groups =
              projectSampleGroups[projectName] ?? const <List<double>>[];
          return index < groups.length
              ? List<double>.from(groups[index])
              : <double>[];
        }),
        docDistributions: List<Map<String, dynamic>>.from(
          projectDocDistributions[projectName] ??
              const <Map<String, dynamic>>[],
        ),
        boxHeaviest: (projectBoxValues[projectName]?['heaviest'] ?? ''),
        boxAverage: (projectBoxValues[projectName]?['average'] ?? ''),
        boxLightest: (projectBoxValues[projectName]?['lightest'] ?? ''),
        dietPens: {
          for (final entry
              in (projectDietPenSelections[projectName] ??
                      const <int, List<int>>{})
                  .entries)
            entry.key: List<int>.from(entry.value),
        },
        dietInputs: {
          for (final entry
              in (projectDietInputValues[projectName] ??
                      const <int, Map<String, String>>{})
                  .entries)
            entry.key: Map<String, String>.from(entry.value),
        },
      );
      return true;
    } catch (error) {
      debugPrint('Firestore sync failed for $projectName: $error');
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
    if (raw is! Map)
      return const <List<double>>[<double>[], <double>[], <double>[]];
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

  List<Map<String, dynamic>> _parseDocDistributions(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> hydrateStepperDataFromFirestore(String projectName) async {
    try {
      final record = await _firestoreService.getProjectRecord(
        projectName: projectName,
      );
      if (record == null) return;

      final sampleWeights = _parseSampleWeights(record['sample_weights']);
      final sampleGroups = _parseSampleGroups(record['sample_groups']);
      final docDistributions = _parseDocDistributions(
        record['doc_distributions'],
      );
      final dietPens = _parseDietPens(record['diet_pen_selections']);
      final dietInputs = _parseDietInputs(record['diet_input_values']);

      projectSampleWeights[projectName] = sampleWeights;
      projectSampleGroups[projectName] = sampleGroups;
      projectDocDistributions[projectName] = docDistributions;
      projectBoxValues[projectName] = {
        'heaviest': (record['box_heaviest'] ?? '').toString(),
        'average': (record['box_average'] ?? '').toString(),
        'lightest': (record['box_lightest'] ?? '').toString(),
      };
      projectDietPenSelections[projectName] = dietPens;
      projectDietInputValues[projectName] = dietInputs;

      final dietMappingController = Get.isRegistered<DietMappingController>()
          ? Get.find<DietMappingController>()
          : Get.put(DietMappingController(), permanent: true);

      if (selectedProjectName.value == projectName) {
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
      debugPrint('Failed to hydrate stepper data for $projectName: $error');
    }
  }

  Future<void> markDrafted(String projectName, {int step = 1}) async {
    projectStatuses[projectName] = BroilerWorkflowStatus.drafted;
    projectStatuses.refresh();
    updateLastOpenedStep(projectName, step);
    await _syncProjectToFirestore(projectName);
  }

  Future<void> markInProgress(String projectName) async {
    projectStatuses[projectName] = BroilerWorkflowStatus.inProgress;
    projectStatuses.refresh();
    projects.refresh(); // Notify observers that projects related data changed
    _notifyStatusChange();
    updateLastOpenedStep(projectName, 2);
    await _syncProjectToFirestore(projectName);
  }

  void updateLastOpenedStep(String projectName, int step) {
    projectLastOpenedSteps[projectName] = step.clamp(0, 2);
  }

  Future<bool> saveStepperData({
    required String projectName,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
    required List<Map<String, dynamic>> docDistributions,
    required String boxHeaviest,
    required String boxAverage,
    required String boxLightest,
    required Map<int, List<int>> dietPens,
    required Map<int, Map<String, String>> dietInputs,
  }) {
    projectSampleWeights[projectName] = List<double>.from(sampleWeights);
    projectSampleGroups[projectName] = List<List<double>>.generate(
      3,
      (index) => index < sampleGroups.length
          ? List<double>.from(sampleGroups[index])
          : <double>[],
    );
    projectDocDistributions[projectName] = List<Map<String, dynamic>>.from(
      docDistributions,
    );
    projectBoxValues[projectName] = {
      'heaviest': boxHeaviest,
      'average': boxAverage,
      'lightest': boxLightest,
    };
    projectDietPenSelections[projectName] = {
      for (final entry in dietPens.entries)
        entry.key: List<int>.from(entry.value),
    };
    projectDietInputValues[projectName] = {
      for (final entry in dietInputs.entries)
        entry.key: Map<String, String>.from(entry.value),
    };

    return _syncProjectToFirestore(projectName);
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

    final data = BroilerProjectData(
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
      (item) => item.projectName == projectName,
    );
    if (existingIndex >= 0) {
      projects[existingIndex] = data;
    } else {
      projects.add(data);
    }

    selectedProjectName.value = projectName;

    final dietMappingController = Get.isRegistered<DietMappingController>()
        ? Get.find<DietMappingController>()
        : Get.put(DietMappingController(), permanent: true);
    dietMappingController.syncFromValues(diet: diet, replication: replication);

    final saved = await _syncProjectToFirestore(projectName);
    if (saved) {
      Get.snackbar('Draft', 'Project saved to draft');
      return true;
    }

    Get.snackbar('Save Failed', 'Project could not be saved to Firebase');
    return false;
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
