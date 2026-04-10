import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'diet_mapping_controller.dart';
import '../models/broiler_project_data.dart';

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
  final projectBoxValues = <String, Map<String, String>>{}.obs;
  final projectDietPenSelections = <String, Map<int, List<int>>>{}.obs;
  final projectDietInputValues = <String, Map<int, Map<String, String>>>{}.obs;

  VoidCallback? _onStatusChangeCallback;

  List<String> get projectNames =>
      projects.map((item) => item.projectName).toList();

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

  void markDrafted(String projectName, {int step = 1}) {
    if (statusFor(projectName) != BroilerWorkflowStatus.inProgress) {
      projectStatuses[projectName] = BroilerWorkflowStatus.drafted;
    }
    updateLastOpenedStep(projectName, step);
  }

  void markInProgress(String projectName) {
    projectStatuses[projectName] = BroilerWorkflowStatus.inProgress;
    projectStatuses.refresh();
    projects.refresh(); // Notify observers that projects related data changed
    _notifyStatusChange();
    updateLastOpenedStep(projectName, 2);
  }

  void updateLastOpenedStep(String projectName, int step) {
    projectLastOpenedSteps[projectName] = step.clamp(0, 2);
  }

  void saveStepperData({
    required String projectName,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
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

  bool saveProject() {
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

    Get.snackbar('Draft', 'Project saved to draft');
    return true;
  }

  @override
  void onClose() {
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
