import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SampleDocController extends GetxController {
  final boxHeaviestController = TextEditingController();
  final boxAverageController = TextEditingController();
  final boxLightestController = TextEditingController();
  final docWeights = <double>[].obs;
  final sampleGroups = <List<double>>[<double>[], <double>[], <double>[]].obs;
  final sampleGroupBluetoothFlags = <List<bool>>[
    <bool>[],
    <bool>[],
    <bool>[],
  ].obs;
  final docDistributions = <Map<String, dynamic>>[].obs;
  final sampleInputBluetooth = false.obs;
  final distributionBluetooth = false.obs;
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

    if (sampleGroupBluetoothFlags.length < 3) {
      sampleGroupBluetoothFlags.assignAll([<bool>[], <bool>[], <bool>[]]);
    }
    for (var i = 0; i < 3; i++) {
      final current = i < sampleGroupBluetoothFlags.length
          ? List<bool>.from(sampleGroupBluetoothFlags[i])
          : <bool>[];
      if (current.length < normalized[i].length) {
        current.addAll(
          List<bool>.filled(normalized[i].length - current.length, false),
        );
      } else if (current.length > normalized[i].length) {
        current.removeRange(normalized[i].length, current.length);
      }
      sampleGroupBluetoothFlags[i] = current;
    }
    _notifyChanges();
  }

  void setSampleGroupBluetoothFlags(List<List<bool>> flags) {
    final normalized = List<List<bool>>.generate(
      3,
      (index) =>
          index < flags.length ? List<bool>.from(flags[index]) : <bool>[],
    );
    sampleGroupBluetoothFlags.assignAll(normalized);
    _notifyChanges();
  }

  void setDocDistributions(List<Map<String, dynamic>> distributions) {
    docDistributions.assignAll(distributions);
    _notifyChanges();
  }

  void setSampleInputBluetooth(bool value) {
    sampleInputBluetooth.value = value;
    _notifyChanges();
  }

  void setDistributionBluetooth(bool value) {
    distributionBluetooth.value = value;
    _notifyChanges();
  }

  void clearSampleData() {
    boxHeaviestController.clear();
    boxAverageController.clear();
    boxLightestController.clear();
    docWeights.clear();
    sampleGroups.assignAll([<double>[], <double>[], <double>[]]);
    sampleGroupBluetoothFlags.assignAll([<bool>[], <bool>[], <bool>[]]);
    docDistributions.clear();
    sampleInputBluetooth.value = false;
    distributionBluetooth.value = false;
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
