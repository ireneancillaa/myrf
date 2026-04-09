import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SampleDocController extends GetxController {
  final boxHeaviestController = TextEditingController();
  final boxAverageController = TextEditingController();
  final boxLightestController = TextEditingController();
  final docWeights = <double>[].obs;
  final docDistributions = <Map<String, dynamic>>[].obs;
  final totalPens = 10.obs;

  @override
  void onClose() {
    boxHeaviestController.dispose();
    boxAverageController.dispose();
    boxLightestController.dispose();
    super.onClose();
  }
}
