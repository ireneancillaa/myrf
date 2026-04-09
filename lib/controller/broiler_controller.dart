import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/broiler_project_data.dart';

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
  final dietCount = RxnInt();
  final dietReplication = RxnInt();
  final dietPenSelections = <int, List<int>>{}.obs;

  // Sample DOC section
  final boxHeaviestController = TextEditingController();
  final boxAverageController = TextEditingController();
  final boxLightestController = TextEditingController();
  final docWeights = <double>[].obs;
  final docDistributions = <Map<String, dynamic>>[].obs;
  final totalPens = 10.obs;

  List<String> get projectNames =>
      projects.map((item) => item.projectName).toList();

  List<int> dietPensFor(int dietNumber) {
    return List<int>.from(dietPenSelections[dietNumber] ?? const <int>[]);
  }

  Set<int> usedPensExcept(int dietNumber) {
    final usedPens = <int>{};
    for (final entry in dietPenSelections.entries) {
      if (entry.key == dietNumber) continue;
      usedPens.addAll(entry.value);
    }
    return usedPens;
  }

  void updateDietPens(int dietNumber, List<int> pens) {
    dietPenSelections[dietNumber] = List<int>.from(pens)..sort();
    dietPenSelections.refresh();
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
    dietCount.value = int.tryParse(project.diet);
    dietReplication.value = project.dietReplication;
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
      Get.snackbar('Project Name / Chick Cycle', 'Field wajib diisi');
      return false;
    }
    if (trialDate.isEmpty) {
      Get.snackbar('Date Trial', 'Field wajib diisi');
      return false;
    }
    if (docWeight.isEmpty) {
      Get.snackbar('DOC Weight (Kg)', 'Field wajib diisi');
      return false;
    }
    if (docInDate.isEmpty) {
      Get.snackbar('DOC In', 'Field wajib diisi');
      return false;
    }
    if (trialHouse.isEmpty) {
      Get.snackbar('Map of Trial House', 'Field wajib diisi');
      return false;
    }
    if (diet.isEmpty) {
      Get.snackbar('Diet', 'Field wajib diisi');
      return false;
    }
    if (replication.isEmpty) {
      Get.snackbar('Replication', 'Field wajib diisi');
      return false;
    }

    final dietNumber = (int.tryParse(diet) ?? 1).clamp(1, 9999);
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
    dietCount.value = dietNumber;
    dietReplication.value = replicationNumber;

    // Keep pen selections valid when diet count changes.
    dietPenSelections.removeWhere((key, value) => key > dietNumber);
    dietPenSelections.refresh();

    Get.snackbar('Saved', 'Project tersimpan di dropdown');
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
    boxHeaviestController.dispose();
    boxAverageController.dispose();
    boxLightestController.dispose();
    super.onClose();
  }
}
