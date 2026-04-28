import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'broiler_controller.dart';
import 'user_session_controller.dart';
import 'history_controller.dart';
import '../models/activity_log.dart';
import '../services/monitoring_firestore_service.dart';

class MaleBirdsEntry {
  final String id;
  final String date;
  final String age;
  final String male;
  final String female;
  final DateTime recordedAt;

  MaleBirdsEntry({
    this.id = '',
    required this.date,
    required this.age,
    required this.male,
    required this.female,
    required this.recordedAt,
  });

  factory MaleBirdsEntry.fromJson(Map<String, dynamic> json) {
    return MaleBirdsEntry(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      age: json['age'] ?? '-',
      male: json['male'] ?? '-',
      female: json['female'] ?? '-',
      recordedAt:
          (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'age': age, 'male': male, 'female': female};
  }
}

class MaleBirdsController extends GetxController {
  final entries = <MaleBirdsEntry>[].obs;

  late final BroilerController _broilerController;
  late final MonitoringFirestoreService _monitoringService;
  late final UserSessionController _sessionController;
  StreamSubscription? _historySub;

  @override
  void onInit() {
    super.onInit();
    _broilerController = Get.find<BroilerController>();

    _monitoringService = Get.isRegistered<MonitoringFirestoreService>()
        ? Get.find<MonitoringFirestoreService>()
        : Get.put(MonitoringFirestoreService(), permanent: true);

    _sessionController = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);

    ever(_broilerController.selectedProjectId, (String? projectId) {
      _listenToHistory(projectId);
    });
    _listenToHistory(_broilerController.selectedProjectId.value);
  }

  void _listenToHistory(String? projectId) {
    _historySub?.cancel();
    if (projectId == null || projectId.trim().isEmpty) {
      entries.clear();
      return;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    _historySub = _monitoringService
        .watchRecords(
          userId: userId,
          projectId: projectId,
          moduleName: 'male_birds',
        )
        .listen((records) {
          entries.assignAll(
            records.map((r) => MaleBirdsEntry.fromJson(r)).toList(),
          );
        });
  }

  Future<void> addMaleBirds(MaleBirdsEntry entry) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty) {
      Get.snackbar('Error', 'No active project selected.');
      return;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) {
      Get.snackbar('Error', 'User session not found.');
      return;
    }

    await _monitoringService.addRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'male_birds',
      data: entry.toJson(),
    );

    HistoryController.log(
      title: 'Added Male Birds Record',
      description: 'New male birds data recorded: ${entry.male} birds.',
      type: ActivityType.maleBirds,
      projectId: projectId,
    );
  }

  Future<void> deleteMaleBirds(String recordId) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty || recordId.isEmpty) {
      return;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    final success = await _monitoringService.deleteRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'male_birds',
      recordId: recordId,
    );

    if (success) {
      HistoryController.log(
        title: 'Deleted Male Birds Record',
        description: 'A male birds record has been removed.',
        type: ActivityType.maleBirds,
        projectId: projectId,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to delete record from server',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    _historySub?.cancel();
    super.onClose();
  }
}
