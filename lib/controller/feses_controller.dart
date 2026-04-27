import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'broiler_controller.dart';
import 'user_session_controller.dart';
import '../services/monitoring_firestore_service.dart';

class FesesScoreEntry {
  final String id;
  final String date;
  final String age;
  final String penNumber;
  final double fesesKg;
  final double cawanKg;
  final double ovenKg;
  final double totalKg;
  final DateTime recordedAt;

  FesesScoreEntry({
    this.id = '',
    required this.date,
    required this.age,
    required this.penNumber,
    required this.fesesKg,
    required this.cawanKg,
    required this.ovenKg,
    required this.totalKg,
    required this.recordedAt,
  });

  factory FesesScoreEntry.fromJson(Map<String, dynamic> json) {
    return FesesScoreEntry(
      id: (json['id'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      age: (json['age'] ?? '-').toString(),
      penNumber: (json['penNumber'] ?? '').toString(),
      fesesKg: (json['fesesKg'] as num?)?.toDouble() ?? 0.0,
      cawanKg: (json['cawanKg'] as num?)?.toDouble() ?? 0.0,
      ovenKg: (json['ovenKg'] as num?)?.toDouble() ?? 0.0,
      totalKg: (json['totalKg'] as num?)?.toDouble() ?? 0.0,
      recordedAt:
          (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'age': age,
      'penNumber': penNumber,
      'fesesKg': fesesKg,
      'cawanKg': cawanKg,
      'ovenKg': ovenKg,
      'totalKg': totalKg,
    };
  }
}

class FesesController extends GetxController {
  final entries = <FesesScoreEntry>[].obs;

  late final BroilerController _broilerController;
  late final MonitoringFirestoreService _monitoringService;
  late final UserSessionController _sessionController;
  StreamSubscription? _historySub;

  final dateController = TextEditingController();
  final ageController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _broilerController = Get.isRegistered<BroilerController>()
        ? Get.find<BroilerController>()
        : Get.put(BroilerController(), permanent: true);

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

  void initNewFesesScore() {
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthStr = now.month.toString().padLeft(2, '0');
    dateController.text = '$dayStr/$monthStr/${now.year}';
    ageController.clear();
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
        .watchRecords(userId: userId, projectId: projectId, moduleName: 'feses')
        .listen((records) {
          entries.assignAll(
            records.map((r) => FesesScoreEntry.fromJson(r)).toList(),
          );
        });
  }

  Future<void> addFesesScore(FesesScoreEntry entry) async {
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
      moduleName: 'feses',
      data: entry.toJson(),
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
