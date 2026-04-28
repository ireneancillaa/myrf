import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'broiler_controller.dart';
import 'user_session_controller.dart';
import 'history_controller.dart';
import '../services/monitoring_firestore_service.dart';
import '../models/activity_log.dart';

class BoxWeight {
  final String title;
  final int count;
  final double weight;

  BoxWeight({required this.title, required this.count, required this.weight});

  factory BoxWeight.fromJson(Map<String, dynamic> json) {
    return BoxWeight(
      title: json['title'] ?? '',
      count: json['count'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'count': count, 'weight': weight};
  }
}

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
  final List<BoxWeight>? boxWeights;
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
    this.boxWeights,
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
      birdsPens: (json['birdsPens'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      weight: json['weight'] ?? '-',
      weightPens: (json['weightPens'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      boxWeights: (json['boxWeights'] as List?)
          ?.map((e) => BoxWeight.fromJson(e as Map<String, dynamic>))
          .toList(),
      recordedAt:
          (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'boxWeights': boxWeights?.map((e) => e.toJson()).toList(),
    };
  }
}

class WeighingController extends GetxController {
  final weighingHistory = <WeighingRecord>[].obs;

  BroilerController get _broilerController => Get.find<BroilerController>();
  MonitoringFirestoreService get _monitoringService => Get.find<MonitoringFirestoreService>();
  UserSessionController get _sessionController => Get.find<UserSessionController>();
  StreamSubscription? _historySub;

  final dateController = TextEditingController();
  final ageController = TextEditingController();

  final boxWeights = <BoxWeight>[].obs;

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

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    _historySub = _monitoringService
        .watchRecords(
          userId: userId,
          projectId: projectId,
          moduleName: 'weighing',
        )
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
    boxWeights.clear();
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
      boxWeights: boxWeights.isNotEmpty
          ? List<BoxWeight>.from(boxWeights)
          : null,
      recordedAt: DateTime.now(),
    );

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) {
      Get.snackbar('Error', 'User session not found.');
      return;
    }

    await _monitoringService.addRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'weighing',
      data: record.toJson(),
    );

    HistoryController.log(
      title: 'Added Weighing Record',
      description: 'New weighing data recorded for age ${record.age}.',
      type: ActivityType.weighing,
      projectId: projectId,
    );
  }

  Future<void> deleteWeighing(String recordId, String age) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty || recordId.isEmpty) {
      return;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    await _monitoringService.deleteRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'weighing',
      recordId: recordId,
    );

    HistoryController.log(
      title: 'Deleted Weighing Record',
      description: 'Weighing data for age $age has been removed.',
      type: ActivityType.weighing,
      projectId: projectId,
    );
  }

  @override
  void onClose() {
    _historySub?.cancel();
    dateController.dispose();
    ageController.dispose();
    super.onClose();
  }
}
