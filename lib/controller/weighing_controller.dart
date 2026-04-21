import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WeighingRecord {
  final String dateStr;
  final String age;
  final String feed;
  final List<String>? feedPens;
  final String birds;
  final List<String>? birdsPens;
  final String weight;
  final List<String>? weightPens;
  final DateTime recordedAt;

  WeighingRecord({
    required this.dateStr,
    required this.age,
    required this.feed,
    this.feedPens,
    required this.birds,
    this.birdsPens,
    required this.weight,
    this.weightPens,
    required this.recordedAt,
  });
}

class WeighingController extends GetxController {
  final weighingHistory = <WeighingRecord>[].obs;

  // New Form Entry Controllers
  final dateController = TextEditingController();
  final ageController = TextEditingController();

  final box1Controller = TextEditingController();
  final weight1Controller = TextEditingController();

  final box2Controller = TextEditingController();
  final weight2Controller = TextEditingController();

  final feedAndBagValue = RxnString();
  final feedAndBagPens = RxList<String>();
  final lastBirdsValue = RxnString();
  final lastBirdsPens = RxList<String>();
  final actualBirdsValue = RxnString();
  final actualBirdsPens = RxList<String>();
  final birdsWeightValue = RxnString();
  final birdsWeightPens = RxList<String>();

  void initNewWeighing() {
    dateController.clear();
    ageController.clear();
    box1Controller.clear();
    weight1Controller.clear();
    box2Controller.clear();
    weight2Controller.clear();
    feedAndBagValue.value = null;
    feedAndBagPens.clear();
    lastBirdsValue.value = null;
    lastBirdsPens.clear();
    actualBirdsValue.value = null;
    actualBirdsPens.clear();
    birdsWeightValue.value = null;
    birdsWeightPens.clear();
  }

  void saveCurrentWeighing() {
    weighingHistory.insert(
      0,
      WeighingRecord(
        dateStr: dateController.text,
        age: ageController.text.isNotEmpty ? ageController.text : '-',
        feed: feedAndBagValue.value ?? '-',
        feedPens: feedAndBagPens.isNotEmpty
            ? List<String>.from(feedAndBagPens)
            : null,
        birds: lastBirdsValue.value ?? '-',
        birdsPens: lastBirdsPens.isNotEmpty
            ? List<String>.from(lastBirdsPens)
            : null,
        weight: birdsWeightValue.value ?? '-',
        weightPens: birdsWeightPens.isNotEmpty
            ? List<String>.from(birdsWeightPens)
            : null,
        recordedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onClose() {
    dateController.dispose();
    ageController.dispose();
    box1Controller.dispose();
    weight1Controller.dispose();
    box2Controller.dispose();
    weight2Controller.dispose();
    super.onClose();
  }
}
