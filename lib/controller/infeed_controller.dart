import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'broiler_controller.dart';
import 'user_session_controller.dart';
import 'history_controller.dart';
import '../models/activity_log.dart';
import '../services/monitoring_firestore_service.dart';

class InfeedStageData {
  final int stageIndex;
  final String stageName;
  final String dateStr;
  final List<double> penValues;
  final DateTime? updatedAt;

  InfeedStageData({
    required this.stageIndex,
    required this.stageName,
    required this.dateStr,
    required this.penValues,
    this.updatedAt,
  });

  factory InfeedStageData.fromJson(Map<String, dynamic> json, int index) {
    return InfeedStageData(
      stageIndex: index,
      stageName: json['stageName'] ?? '',
      dateStr: json['dateStr'] ?? '',
      penValues:
          (json['penValues'] as List?)
              ?.map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0)
              .toList() ??
          <double>[],
      updatedAt: (json['updated_at'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageName': stageName,
      'dateStr': dateStr,
      'penValues': penValues,
      'updated_at': updatedAt ?? DateTime.now(),
    };
  }

  double get weight => penValues.fold(0, (sum, val) => sum + val);
}

class InfeedController extends GetxController {
  BroilerController get _broilerController => Get.find<BroilerController>();
  MonitoringFirestoreService get _monitoringService => Get.find<MonitoringFirestoreService>();
  UserSessionController get _sessionController => Get.find<UserSessionController>();

  final dateControllers = List.generate(9, (_) => TextEditingController());
  final stageNames = List<String>.filled(9, '').obs;
  final penValuesByStage = List<List<double>>.generate(
    9,
    (_) => <double>[],
  ).obs;
  final stageUpdatedAt = List<DateTime?>.filled(9, null).obs;

  bool get isAllStagesEmpty =>
      penValuesByStage.every((values) => values.isEmpty);

  List<InfeedStageData> get infeedList {
    final list = <InfeedStageData>[];
    final counts = <String, int>{};
    
    for (var i = 0; i < 9; i++) {
      if (penValuesByStage[i].isNotEmpty) {
        final baseName = stageNames[i];
        counts[baseName] = (counts[baseName] ?? 0) + 1;
        final displayNum = counts[baseName]!;
        
        list.add(
          InfeedStageData(
            stageIndex: i,
            stageName: '$baseName $displayNum',
            dateStr: dateControllers[i].text,
            penValues: penValuesByStage[i],
            updatedAt: stageUpdatedAt[i],
          ),
        );
      }
    }
    return list;
  }

  StreamSubscription? _historySub;

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
    _clearData();
    if (projectId == null || projectId.trim().isEmpty) {
      return;
    }

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    _historySub = _monitoringService
        .watchRecords(
          userId: userId,
          projectId: projectId,
          moduleName: 'infeed',
        )
        .listen((records) {
          for (final record in records) {
            final id = record['id'] as String;
            if (id.startsWith('stage_')) {
              final index = int.tryParse(id.replaceFirst('stage_', ''));
              if (index != null && index >= 0 && index < 9) {
                final stageData = InfeedStageData.fromJson(record, index);
                dateControllers[index].text = stageData.dateStr;
                stageNames[index] = stageData.stageName;
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
      stageNames[i] = '';
      penValuesByStage[i] = <double>[];
      stageUpdatedAt[i] = null;
    }
  }

  void resetData() {
    _clearData();
  }

  int getFirstEmptyIndex() {
    for (int i = 0; i < 9; i++) {
      if (penValuesByStage[i].isEmpty) {
        return i;
      }
    }
    return -1; // All slots full
  }

  Future<void> saveStage({
    required int stageIndex,
    required String stageName,
    required String dateStr,
    required List<double> values,
  }) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty) {
      Get.snackbar('Error', 'No active project selected.');
      return;
    }

    dateControllers[stageIndex].text = dateStr;
    stageNames[stageIndex] = stageName;
    penValuesByStage[stageIndex] = List<double>.from(values);
    stageUpdatedAt[stageIndex] = DateTime.now();

    final stageData = InfeedStageData(
      stageIndex: stageIndex,
      stageName: stageName,
      dateStr: dateStr,
      penValues: values,
      updatedAt: DateTime.now(),
    );

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) {
      Get.snackbar('Error', 'User session not found.');
      return;
    }

    await _monitoringService.setRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'infeed',
      recordId: 'stage_$stageIndex',
      data: stageData.toJson(),
    );

    HistoryController.log(
      title: 'Updated Infeed Record',
      description: 'Infeed data updated for stage "$stageName".',
      type: ActivityType.infeed,
      projectId: projectId,
    );
  }

  Future<void> deleteStage(int index) async {
    final projectId = _broilerController.selectedProjectId.value;
    if (projectId == null || projectId.trim().isEmpty) return;

    final userId = _sessionController.userId.value;
    if (userId.isEmpty) return;

    final stageName = stageNames[index];

    // Clear local data
    dateControllers[index].clear();
    stageNames[index] = '';
    penValuesByStage[index] = <double>[];
    stageUpdatedAt[index] = null;

    // Delete from Firestore
    await _monitoringService.deleteRecord(
      userId: userId,
      projectId: projectId,
      moduleName: 'infeed',
      recordId: 'stage_$index',
    );

    HistoryController.log(
      title: 'Deleted Infeed Record',
      description: 'Infeed data deleted for stage "$stageName".',
      type: ActivityType.infeed,
      projectId: projectId,
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
