import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log.dart';

class ActivityFirestoreService {
  ActivityFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _activityCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('activities');

  Future<void> logActivity({
    required String userId,
    required ActivityLog log,
  }) async {
    if (userId.isEmpty) return;
    try {
      // Use timestamp as ID for deterministic ordering and to match broiler record pattern
      final docId = log.timestamp.millisecondsSinceEpoch.toString();
      await _activityCollection(userId).doc(docId).set(log.toJson());
    } catch (e) {
      // Log error internally or ignore for audit logs
    }
  }

  Stream<List<ActivityLog>> watchActivities({required String userId}) {
    if (userId.isEmpty) return Stream.value([]);
    return _activityCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ActivityLog.fromJson(doc.data(), id: doc.id);
          }).toList();
        });
  }
}
