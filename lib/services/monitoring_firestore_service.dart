import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoringFirestoreService {
  MonitoringFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String baseCollection = 'broiler_records';

  CollectionReference<Map<String, dynamic>> _moduleCollection(
    String projectId,
    String moduleName,
  ) {
    return _firestore
        .collection(baseCollection)
        .doc(projectId.trim())
        .collection(moduleName);
  }

  Stream<List<Map<String, dynamic>>> watchRecords({
    required String projectId,
    required String moduleName,
    String orderByField = 'created_at',
  }) {
    if (projectId.trim().isEmpty) return Stream.value([]);
    return _moduleCollection(projectId, moduleName)
        .orderBy(orderByField, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getRecordsOnce({
    required String projectId,
    required String moduleName,
    String orderByField = 'created_at',
  }) async {
    if (projectId.trim().isEmpty) return [];
    try {
      final snapshot = await _moduleCollection(projectId, moduleName)
          .orderBy(orderByField, descending: true)
          .get();
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
    required String projectId,
    required String moduleName,
    required Map<String, dynamic> data,
  }) async {
    if (projectId.trim().isEmpty) return null;
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!payload.containsKey('created_at')) {
        payload['created_at'] = FieldValue.serverTimestamp();
      }
      payload['updated_at'] = FieldValue.serverTimestamp();

      final docRef =
          await _moduleCollection(projectId, moduleName).add(payload);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateRecord({
    required String projectId,
    required String moduleName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (projectId.trim().isEmpty || recordId.trim().isEmpty) return false;
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['updated_at'] = FieldValue.serverTimestamp();
      await _moduleCollection(projectId, moduleName).doc(recordId).update(
        payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRecord({
    required String projectId,
    required String moduleName,
    required String recordId,
  }) async {
    if (projectId.trim().isEmpty || recordId.trim().isEmpty) return false;
    try {
      await _moduleCollection(projectId, moduleName).doc(recordId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setRecord({
    required String projectId,
    required String moduleName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (projectId.trim().isEmpty || recordId.trim().isEmpty) return;
    try {
      final docRef = _moduleCollection(projectId, moduleName).doc(recordId);
      final snapshot = await docRef.get();
      final payload = Map<String, dynamic>.from(data);
      if (!snapshot.exists) {
        if (!payload.containsKey('created_at')) {
          payload['created_at'] = FieldValue.serverTimestamp();
        }
      }
      payload['updated_at'] = FieldValue.serverTimestamp();

      await docRef.set(payload, SetOptions(merge: true));
    } catch (_) {}
  }
}
