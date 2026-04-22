import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'broiler_controller.dart';
import '../services/monitoring_firestore_service.dart';

class WeighingRecord {
  final String id;
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
    this.id = '',
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

  factory WeighingRecord.fromJson(Map<String, dynamic> json) {
    return WeighingRecord(
      id: json['id'] ?? '',
      dateStr: json['dateStr'] ?? '',
      age: json['age'] ?? '-',
      feed: json['feed'] ?? '-',
      feedPens: (json['feedPens'] as List?)?.map((e) => e.toString()).toList(),
      birds: json['birds'] ?? '-',
      birdsPens: (json['birdsPens'] as List?)?.map((e) => e.toString()).toList(),
      weight: json['weight'] ?? '-',
      weightPens: (json['weightPens'] as List?)?.map((e) => e.toString()).toList(),
      recordedAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateStr': dateStr,
      'age': age,
      'feed': feed,
      'feedPens': feedPens,
      'birds': birds,
      'birdsPens': birdsPens,
      'weight': weight,
      'weightPens': weightPens,
    };
  }
}

class WeighingController extends GetxController {
  final weighingHistory = <WeighingRecord>[].obs;

  late final BroilerController _broilerController;
  late final MonitoringFirestoreService _monitoringService;
  StreamSubscription? _historySub;

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

  @override
  void onInit() {
    super.onInit();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);

    _monitoringService = Get.isRegistered<MonitoringFirestoreService>()
        ? Get.find<MonitoringFirestoreService>()
        : Get.put(MonitoringFirestoreService(), permanent: true);

    ever(_broilerController.selectedProjectId, (String? projectId) {
      _listenToHistory(projectId);
    });
    _listenToHistory(_broilerController.selectedProjectId.value);
  }

  void _listenToHistory(String? projectId) {
    _historySub?.cancel();
    if (projectId == null || projectId.trim().isEmpty) {
      weighingHistory.clear();
      return;
    }

    _historySub = _monitoringService
        .watchRecords(projectId: projectId, moduleName: 'weighing')
        .listen((records) {
      weighingHistory.assignAll(
        records.map((r) => WeighingRecord.fromJson(r)).toList(),
      );
    });
  }

  void initNewWeighing() {
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthStr = now.month.toString().padLeft(2, '0');
    dateController.text = '$dayStr/$monthStr/${now.year}';

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

  Future<void> saveCurrentWeighing() async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty) {
      Get.snackbar('Error', 'No active project selected.');
      return;
    }

    final record = WeighingRecord(
      dateStr: dateController.text,
      age: ageController.text.isNotEmpty ? ageController.text : '-',
      feed: feedAndBagValue.value ?? '-',
      feedPens: feedAndBagPens.isNotEmpty ? List<String>.from(feedAndBagPens) : null,
      birds: lastBirdsValue.value ?? '-',
      birdsPens: lastBirdsPens.isNotEmpty ? List<String>.from(lastBirdsPens) : null,
      weight: birdsWeightValue.value ?? '-',
      weightPens: birdsWeightPens.isNotEmpty ? List<String>.from(birdsWeightPens) : null,
      recordedAt: DateTime.now(),
    );

    await _monitoringService.addRecord(
      projectId: projectId,
      moduleName: 'weighing',
      data: record.toJson(),
    );
  }

  @override
  void onClose() {
    _historySub?.cancel();
    dateController.dispose();
    ageController.dispose();
    box1Controller.dispose();
    weight1Controller.dispose();
    box2Controller.dispose();
    weight2Controller.dispose();
    super.onClose();
  }
}
