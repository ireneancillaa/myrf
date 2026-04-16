import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/broiler_project_data.dart';

class BroilerFirestoreService {
  BroilerFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'broiler_records';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<Map<String, dynamic>?> getProjectRecord({
    required String projectId,
  }) async {
    final docRef = _collection.doc(projectId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  Stream<Map<String, String>> watchProjectStatuses() {
    return _collection.snapshots().map((snapshot) {
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

  Stream<List<BroilerProjectData>> watchProjects() {
    return _collection.orderBy('updated_at', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => _toProjectData(doc.id, doc.data()))
          .whereType<BroilerProjectData>()
          .toList();
    });
  }

  BroilerProjectData? _toProjectData(String docId, Map<String, dynamic> data) {
    final projectName = (data['project_name'] as String?)?.trim() ?? '';
    if (projectName.isEmpty) return null;

    final dietReplicationValue = data['diet_replication'];
    int? dietReplication;
    if (dietReplicationValue is int) {
      dietReplication = dietReplicationValue;
    } else if (dietReplicationValue is String) {
      dietReplication = int.tryParse(dietReplicationValue);
    }

    final rawProjectId = (data['project_id'] as String?)?.trim() ?? '';

    return BroilerProjectData(
      projectId: rawProjectId.isNotEmpty ? rawProjectId : docId,
      projectName: projectName,
      trialDate: (data['trial_date'] as String?) ?? '',
      trialHouse: (data['trial_house'] as String?) ?? '',
      strain: (data['strain'] as String?) ?? '',
      hatchery: (data['hatchery'] as String?) ?? '',
      breedingFarm: (data['breeding_farm'] as String?) ?? '',
      boxBatchCode: (data['box_batch_code'] as String?) ?? '',
      selector: (data['selector'] as String?) ?? '',
      docInDate: (data['doc_in_date'] as String?) ?? '',
      docWeight: (data['doc_weight'] as String?) ?? '',
      weighing3Weeks: (data['weighing_3_weeks'] as String?) ?? '',
      weighing5Weeks: (data['weighing_5_weeks'] as String?) ?? '',
      numberOfBirds: (data['number_of_birds'] as String?) ?? '',
      diet: (data['diet'] as String?) ?? '',
      replication: (data['replication'] as String?) ?? '',
      dietReplication: dietReplication,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Future<String> upsertProjectRecord({
    String? projectId,
    required BroilerProjectData data,
    required String status,
    required List<double> sampleWeights,
    required List<List<double>> sampleGroups,
    required List<List<bool>> sampleGroupBluetoothFlags,
    required List<Map<String, dynamic>> docDistributions,
    required bool sampleInputBluetooth,
    required bool distributionBluetooth,
    required String boxHeaviest,
    required String boxAverage,
    required String boxLightest,
    required Map<int, List<int>> dietPens,
    required Map<int, Map<String, String>> dietInputs,
  }) async {
    final hasProjectId = projectId != null && projectId.trim().isNotEmpty;
    final docRef = hasProjectId
        ? _collection.doc(projectId.trim())
        : _collection.doc();

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
      'status': status,
      'status_updated_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      payload['created_at'] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> deleteProjectRecord({required String projectId}) async {
    final docRef = _collection.doc(projectId);
    await docRef.delete();
  }
}
