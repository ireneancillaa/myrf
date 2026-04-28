import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'broiler_controller.dart';
import 'user_session_controller.dart';
import 'history_controller.dart';
import '../models/activity_log.dart';
import '../services/monitoring_firestore_service.dart';

class DepletionEntry {
  final String id;
  final String type;
  final String? gender;
  final String date;
  final String age;
  final String penNumber;
  final String bodyWeight;
  final String? remarks;
  final DateTime recordedAt;

  DepletionEntry({
    this.id = '',
    required this.type,
    required this.gender,
    required this.date,
    required this.age,
    required this.penNumber,
    required this.bodyWeight,
    this.remarks,
    required this.recordedAt,
  });

  factory DepletionEntry.fromJson(Map<String, dynamic> json) {
    return DepletionEntry(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      gender: json['gender'],
      date: json['date'] ?? '',
      age: json['age'] ?? '-',
      penNumber: json['penNumber'] ?? '-',
      bodyWeight: json['bodyWeight'] ?? '-',
      remarks: json['remarks'],
      recordedAt:
          (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'gender': gender,
      'date': date,
      'age': age,
      'penNumber': penNumber,
      'bodyWeight': bodyWeight,
      'remarks': remarks,
    };
  }
}

class MortalityController extends GetxController {
  final entries = <DepletionEntry>[].obs;

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
          moduleName: 'mortality',
        )
        .listen((records) {
          entries.assignAll(
            records.map((r) => DepletionEntry.fromJson(r)).toList(),
          );
        });
  }

  Future<void> addDepletion(DepletionEntry entry) async {
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
      moduleName: 'mortality',
      data: entry.toJson(),
    );

    HistoryController.log(
      title: 'Added Mortality Record',
      description: 'New mortality data recorded for Pen ${entry.penNumber}.',
      type: ActivityType.mortality,
      projectId: projectId,
    );
  }

  Future<void> deleteDepletion(String recordId, String penNumber) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty || recordId.isEmpty) {
      return;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    await _monitoringService.deleteRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'mortality',
      recordId: recordId,
    );

    HistoryController.log(
      title: 'Deleted Mortality Record',
      description: 'Mortality data for Pen $penNumber has been removed.',
      type: ActivityType.mortality,
      projectId: projectId,
    );
  }


  @override
  void onClose() {
    _historySub?.cancel();
    super.onClose();
  }
}
