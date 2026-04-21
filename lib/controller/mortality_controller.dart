import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'broiler_controller.dart';
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
      recordedAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
        .watchRecords(projectId: projectId, moduleName: 'mortality')
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

    await _monitoringService.addRecord(
      projectId: projectId,
      moduleName: 'mortality',
      data: entry.toJson(),
    );
  }

  @override
  void onClose() {
    _historySub?.cancel();
    super.onClose();
  }
}
