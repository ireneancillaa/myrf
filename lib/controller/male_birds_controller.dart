import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'broiler_controller.dart';
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
      recordedAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'age': age,
      'male': male,
      'female': female,
    };
  }
}

class MaleBirdsController extends GetxController {
  final entries = <MaleBirdsEntry>[].obs;

  late final BroilerController _broilerController;
  late final MonitoringFirestoreService _monitoringService;
  StreamSubscription? _historySub;

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
      entries.clear();
      return;
    }

    _historySub = _monitoringService
        .watchRecords(projectId: projectId, moduleName: 'male_birds')
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

    await _monitoringService.addRecord(
      projectId: projectId,
      moduleName: 'male_birds',
      data: entry.toJson(),
    );
  }

  Future<void> deleteMaleBirds(String recordId) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty || recordId.isEmpty) {
      return;
    }

    final success = await _monitoringService.deleteRecord(
      projectId: projectId,
      moduleName: 'male_birds',
      recordId: recordId,
    );

    if (!success) {
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
