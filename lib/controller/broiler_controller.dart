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

  final projects = <BroilerProjectData>[].obs;
  final selectedProjectName = RxnString();
  final selectedTrialHouse = RxnString();
  final selectedStrain = RxnString();
  final selectedHatchery = RxnString();
  final selectedDocInDate = RxnString();
  final dietReplication = RxnInt();
  final dietPenSelections = <int, List<int>>{}.obs;

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
    selectedTrialHouse.value = project.trialHouse;
    selectedStrain.value = project.strain;
    selectedHatchery.value = project.hatchery;
    selectedDocInDate.value = project.docInDate;
    dietReplication.value = project.dietReplication;
  }

  void saveProject() {
    final projectName = projectNameController.text.trim();
    if (projectName.isEmpty) {
      Get.snackbar('Project Name', 'Project name belum diisi');
      return;
    }

    final data = BroilerProjectData(
      projectName: projectName,
      trialDate: trialDateController.text.trim(),
      trialHouse: trialHouseController.text.trim(),
      strain: strainController.text.trim(),
      hatchery: hatcheryController.text.trim(),
      breedingFarm: breedingFarmController.text.trim(),
      boxBatchCode: boxBatchCodeController.text.trim(),
      selector: selectorController.text.trim(),
      docInDate: docInDateController.text.trim(),
      docWeight: docWeightController.text.trim(),
      weighing3Weeks: weighing3WeeksController.text.trim(),
      weighing5Weeks: weighing5WeeksController.text.trim(),
      numberOfBirds: numberOfBirdsController.text.trim(),
      dietReplication: dietReplication.value,
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
    Get.snackbar('Saved', 'Project tersimpan di dropdown');
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
    super.onClose();
  }
}
