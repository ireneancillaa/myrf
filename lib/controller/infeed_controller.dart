import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'broiler_controller.dart';
import '../services/monitoring_firestore_service.dart';

class InfeedStageData {
  final int stageIndex;
  final String dateStr;
  final List<double> penValues;
  final DateTime? updatedAt;

  InfeedStageData({
    required this.stageIndex,
    required this.dateStr,
    required this.penValues,
    this.updatedAt,
  });

  factory InfeedStageData.fromJson(Map<String, dynamic> json, int index) {
    return InfeedStageData(
      stageIndex: index,
      dateStr: json['dateStr'] ?? '',
      penValues: (json['penValues'] as List?)
              ?.map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0)
              .toList() ??
          <double>[],
      updatedAt: (json['updated_at'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateStr': dateStr,
      'penValues': penValues,
    };
  }
}

class InfeedController extends GetxController {
  late final BroilerController _broilerController;
  late final MonitoringFirestoreService _monitoringService;

  final dateControllers = List.generate(9, (_) => TextEditingController());
  final penValuesByStage = List<List<double>>.generate(9, (_) => <double>[]).obs;
  final stageUpdatedAt = List<DateTime?>.filled(9, null).obs;

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
    _clearData();
    if (projectId == null || projectId.trim().isEmpty) {
      return;
    }

    _historySub = _monitoringService
        .watchRecords(projectId: projectId, moduleName: 'infeed')
        .listen((records) {
      for (final record in records) {
        final id = record['id'] as String;
        if (id.startsWith('stage_')) {
          final index = int.tryParse(id.replaceFirst('stage_', ''));
          if (index != null && index >= 0 && index < 9) {
            final stageData = InfeedStageData.fromJson(record, index);
            dateControllers[index].text = stageData.dateStr;
            penValuesByStage[index] = stageData.penValues;
            stageUpdatedAt[index] = stageData.updatedAt;
          }
        }
      }
    });
  }

  void _clearData() {
    for (var i = 0; i < 9; i++) {
      dateControllers[i].clear();
      penValuesByStage[i] = <double>[];
      stageUpdatedAt[i] = null;
    }
  }

  Future<void> saveStage(int stageIndex, String dateStr, List<double> values) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty) {
      Get.snackbar('Error', 'No active project selected.');
      return;
    }

    dateControllers[stageIndex].text = dateStr;
    penValuesByStage[stageIndex] = List<double>.from(values);
    stageUpdatedAt[stageIndex] = DateTime.now();

    final stageData = InfeedStageData(
      stageIndex: stageIndex,
      dateStr: dateStr,
      penValues: values,
      updatedAt: DateTime.now(),
    );

    await _monitoringService.setRecord(
      projectId: projectId,
      moduleName: 'infeed',
      recordId: 'stage_$stageIndex',
      data: stageData.toJson(),
    );
  }

  @override
  void onClose() {
    _historySub?.cancel();
    for (final c in dateControllers) {
      c.dispose();
    }
    super.onClose();
  }
}
