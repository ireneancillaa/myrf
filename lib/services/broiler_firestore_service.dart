import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/broiler_project_data.dart';

class BroilerFirestoreService {
  BroilerFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'broiler_records';

  CollectionReference<Map<String, dynamic>> _userCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection(collectionName);

  Future<Map<String, dynamic>?> getProjectRecord({
    required String userId,
    required String projectId,
  }) async {
    final docRef = _userCollection(userId).doc(projectId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  Stream<Map<String, String>> watchProjectStatuses(String userId) {
    return _userCollection(userId).snapshots().map((snapshot) {
      final statuses = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final projectId =
            (data['project_id'] as String?)?.trim().isNotEmpty == true
            ? (data['project_id'] as String).trim()
            : doc.id;
        final status = (data['status'] as String?)?.trim() ?? 'drafted';
        statuses[projectId] = status;
      }
      return statuses;
    });
  }

  Stream<List<BroilerProjectData>> watchProjects(String userId) {
    return _userCollection(userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _toProjectData(doc.id, doc.data()))
              .whereType<BroilerProjectData>()
              .toList();
        })
        .handleError((error) {
          debugPrint(
            'BroilerFirestoreService: Error watching projects: $error',
          );
        });
  }

  BroilerProjectData? _toProjectData(String docId, Map<String, dynamic> data) {
    String safeString(dynamic value) => value?.toString() ?? '';

    final projectName = safeString(data['project_name']);
    final finalProjectName = projectName.isEmpty ? '(No Name)' : projectName;

    debugPrint(
      'BroilerFirestoreService: Mapping doc $docId - name: $finalProjectName',
    );

    final dietReplicationValue = data['diet_replication'];
    int? dietReplication;
    if (dietReplicationValue is int) {
      dietReplication = dietReplicationValue;
    } else if (dietReplicationValue is String) {
      dietReplication = int.tryParse(dietReplicationValue);
    } else if (dietReplicationValue is double) {
      dietReplication = dietReplicationValue.toInt();
    }

    final rawProjectId = safeString(data['project_id']);

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return BroilerProjectData(
      projectId: rawProjectId.isNotEmpty ? rawProjectId : docId,
      projectName: finalProjectName,
      trialDate: safeString(data['trial_date']),
      trialHouse: safeString(data['trial_house']),
      strain: safeString(data['strain']),
      hatchery: safeString(data['hatchery']),
      breedingFarm: safeString(data['breeding_farm']),
      boxBatchCode: safeString(data['box_batch_code']),
      selector: safeString(data['selector']),
      docInDate: safeString(data['doc_in_date']),
      docWeight: safeString(data['doc_weight']),
      weighing3Weeks: safeString(data['weighing_3_weeks']),
      weighing5Weeks: safeString(data['weighing_5_weeks']),
      numberOfBirds: safeString(data['number_of_birds']),
      diet: safeString(data['diet']),
      replication: safeString(data['replication']),
      dietReplication: dietReplication,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      frontTemp: data['front_temp']?.toString(),
      middleTemp: data['middle_temp']?.toString(),
      rearTemp: data['rear_temp']?.toString(),
      minTemp: parseDouble(data['min_temp']),
      maxTemp: parseDouble(data['max_temp']),
    );
  }

  Future<String> upsertProjectRecord({
    required String userId,
    String? projectId,
    required BroilerProjectData data,
    required String status,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
    required List<List<bool>> sampleGroupBluetoothFlags,
    required List<Map<String, dynamic>> docDistributions,
    required List<String> attachmentUrls,
    required bool sampleInputBluetooth,
    required bool distributionBluetooth,
    required String boxHeaviest,
    required String boxAverage,
    required String boxLightest,
    required Map<int, List<int>> dietPens,
    required Map<int, Map<String, String>> dietInputs,
  }) async {
    final isLocalId = projectId?.startsWith('local_') ?? false;
    final hasProjectId =
        projectId != null && projectId.trim().isNotEmpty && !isLocalId;
    final docRef = hasProjectId
        ? _userCollection(userId).doc(projectId.trim())
        : _userCollection(userId).doc();

    final snapshot = await docRef.get();

    final payload = <String, dynamic>{
      'project_id': docRef.id,
      'project_name': data.projectName,
      'trial_date': data.trialDate,
      'trial_house': data.trialHouse,
      'strain': data.strain,
      'hatchery': data.hatchery,
      'breeding_farm': data.breedingFarm,
      'box_batch_code': data.boxBatchCode,
      'selector': data.selector,
      'doc_in_date': data.docInDate,
      'doc_weight': data.docWeight,
      'weighing_3_weeks': data.weighing3Weeks,
      'weighing_5_weeks': data.weighing5Weeks,
      'number_of_birds': data.numberOfBirds,
      'diet': data.diet,
      'replication': data.replication,
      'diet_replication': data.dietReplication,
      'diet_pen_selections': {
        for (final entry in dietPens.entries) '${entry.key}': entry.value,
      },
      'diet_input_values': {
        for (final entry in dietInputs.entries)
          '${entry.key}': {
            'preStarter': (entry.value['preStarter'] ?? '').trim(),
            'starter': (entry.value['starter'] ?? '').trim(),
            'finisher': (entry.value['finisher'] ?? '').trim(),
          },
      },
      'box_heaviest': boxHeaviest.trim(),
      'box_average': boxAverage.trim(),
      'box_lightest': boxLightest.trim(),
      'sample_weights': List<double>.from(sampleWeights),
      'sample_groups': {
        for (var i = 0; i < 3; i++)
          '$i': i < sampleGroups.length
              ? List<double>.from(sampleGroups[i])
              : <double>[],
      },
      'sample_groups_bluetooth': {
        for (var i = 0; i < 3; i++)
          '$i': i < sampleGroupBluetoothFlags.length
              ? sampleGroupBluetoothFlags[i]
                    .map((flag) => flag ? 'yes' : 'no')
                    .toList()
              : <String>[],
      },
      'sample_is_bluetooth': sampleInputBluetooth ? 'yes' : 'no',
      'distribution_is_bluetooth': distributionBluetooth ? 'yes' : 'no',
      'is_bluetooth': (sampleInputBluetooth || distributionBluetooth)
          ? 'yes'
          : 'no',
      'doc_distributions': docDistributions
          .map(
            (item) => {
              'pen': item['pen'],
              'valueKg': item['valueKg'],
              'updatedAt': item['updatedAt'],
              'isBluetooth':
                  (item['isBluetooth'] ??
                  (distributionBluetooth ? 'yes' : 'no')),
            },
          )
          .toList(),
      'attachment_urls': attachmentUrls
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'status': status,
      'status_updated_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      payload['created_at'] = FieldValue.serverTimestamp();
      // Initialize empty temperature fields for new projects
      payload['front_temp'] = data.frontTemp;
      payload['middle_temp'] = data.middleTemp;
      payload['rear_temp'] = data.rearTemp;
      payload['min_temp'] = data.minTemp;
      payload['max_temp'] = data.maxTemp;
    } else {
      // Preserve or update temperature fields if they are explicitly passed in data
      if (data.frontTemp != null) payload['front_temp'] = data.frontTemp;
      if (data.middleTemp != null) payload['middle_temp'] = data.middleTemp;
      if (data.rearTemp != null) payload['rear_temp'] = data.rearTemp;
      if (data.minTemp != null) payload['min_temp'] = data.minTemp;
      if (data.maxTemp != null) payload['max_temp'] = data.maxTemp;
    }

    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> deleteProjectRecord({
    required String userId,
    required String projectId,
  }) async {
    final docRef = _userCollection(userId).doc(projectId);
    await docRef.delete();
  }
}
