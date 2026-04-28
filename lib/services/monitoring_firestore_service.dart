import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MonitoringFirestoreService {
  MonitoringFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String baseCollection = 'broiler_records';

  CollectionReference<Map<String, dynamic>> _moduleCollection({
    required String userId,
    required String projectId,
    required String moduleName,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(baseCollection)
        .doc(projectId.trim())
        .collection(moduleName);
  }

  Stream<List<Map<String, dynamic>>> watchRecords({
    required String userId,
    required String projectId,
    required String moduleName,
    String orderByField = 'created_at',
  }) {
    if (projectId.trim().isEmpty) return Stream.value([]);
    return _moduleCollection(
      userId: userId,
      projectId: projectId,
      moduleName: moduleName,
    ).orderBy(orderByField, descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getRecordsOnce({
    required String userId,
    required String projectId,
    required String moduleName,
    String orderByField = 'created_at',
  }) async {
    if (projectId.trim().isEmpty) return [];
    try {
      final snapshot = await _moduleCollection(
        userId: userId,
        projectId: projectId,
        moduleName: moduleName,
      ).orderBy(orderByField, descending: true).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> addRecord({
    required String userId,
    required String projectId,
    required String moduleName,
    required Map<String, dynamic> data,
  }) async {
    if (projectId.trim().isEmpty) return null;
    try {
      final payload = Map<String, dynamic>.from(data);
      final now = DateTime.now();
      if (!payload.containsKey('created_at')) {
        payload['created_at'] = FieldValue.serverTimestamp();
      }
      payload['updated_at'] = FieldValue.serverTimestamp();
      payload['client_timestamp'] = now.toIso8601String();

      // Create a deterministic but unique ID for better Console visibility
      final recordId =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}_"
          "${now.millisecond}";

      final docRef = _moduleCollection(
        userId: userId,
        projectId: projectId,
        moduleName: moduleName,
      ).doc(recordId);

      await docRef.set(payload);

      // Also touch the parent project document to trigger real-time updates in Console
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(baseCollection)
          .doc(projectId.trim())
          .set({
            'last_monitoring_update': FieldValue.serverTimestamp(),
            'last_module': moduleName,
          }, SetOptions(merge: true));

      return recordId;
    } catch (e) {
      debugPrint('MonitoringFirestoreService: Error adding record: $e');
      return null;
    }
  }

  Future<bool> updateRecord({
    required String userId,
    required String projectId,
    required String moduleName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (projectId.trim().isEmpty || recordId.trim().isEmpty) return false;
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['updated_at'] = FieldValue.serverTimestamp();
      await _moduleCollection(
        userId: userId,
        projectId: projectId,
        moduleName: moduleName,
      ).doc(recordId).update(payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRecord({
    required String userId,
    required String projectId,
    required String moduleName,
    required String recordId,
  }) async {
    if (projectId.trim().isEmpty || recordId.trim().isEmpty) return false;
    try {
      await _moduleCollection(
        userId: userId,
        projectId: projectId,
        moduleName: moduleName,
      ).doc(recordId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setRecord({
    required String userId,
    required String projectId,
    required String moduleName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (projectId.trim().isEmpty || recordId.trim().isEmpty) return;
    try {
      final docRef = _moduleCollection(
        userId: userId,
        projectId: projectId,
        moduleName: moduleName,
      ).doc(recordId);
      final snapshot = await docRef.get();
      final payload = Map<String, dynamic>.from(data);
      if (!snapshot.exists) {
        if (!payload.containsKey('created_at')) {
          payload['created_at'] = FieldValue.serverTimestamp();
        }
      }
      payload['updated_at'] = FieldValue.serverTimestamp();

      await docRef.set(payload, SetOptions(merge: true));

      // Also touch the parent project document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('broiler_projects')
          .doc(projectId.trim())
          .set({
            'last_monitoring_update': FieldValue.serverTimestamp(),
            'last_module': moduleName,
          }, SetOptions(merge: true));
    } catch (_) {}
  }
}
