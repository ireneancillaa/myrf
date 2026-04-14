import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SampleDocController extends GetxController {
  final boxHeaviestController = TextEditingController();
  final boxAverageController = TextEditingController();
  final boxLightestController = TextEditingController();
  final docWeights = <double>[].obs;
  final sampleGroups = <List<double>>[<double>[], <double>[], <double>[]].obs;
  final docDistributions = <Map<String, dynamic>>[].obs;
  final totalPens = 10.obs;

  VoidCallback? _onChangeCallback;

  void addChangeListener(VoidCallback callback) {
    _onChangeCallback = callback;
  }

  void _notifyChanges() {
    _onChangeCallback?.call();
  }

  void setSampleGroups(List<List<double>> groups) {
    final normalized = List<List<double>>.generate(
      3,
      (index) =>
          index < groups.length ? List<double>.from(groups[index]) : <double>[],
    );
    sampleGroups.assignAll(normalized);
    docWeights.assignAll(normalized.expand((item) => item).toList());
    _notifyChanges();
  }

  void setDocDistributions(List<Map<String, dynamic>> distributions) {
    docDistributions.assignAll(distributions);
    _notifyChanges();
  }

  void clearSampleData() {
    boxHeaviestController.clear();
    boxAverageController.clear();
    boxLightestController.clear();
    docWeights.clear();
    sampleGroups.assignAll([<double>[], <double>[], <double>[]]);
    docDistributions.clear();
    _notifyChanges();
  }

  @override
  void onClose() {
    boxHeaviestController.dispose();
    boxAverageController.dispose();
    boxLightestController.dispose();
    super.onClose();
  }
}
