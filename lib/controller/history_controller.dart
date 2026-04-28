import 'dart:async';
import 'package:get/get.dart';
import '../models/activity_log.dart';
import '../services/activity_firestore_service.dart';
import 'user_session_controller.dart';
import 'broiler_controller.dart';

class HistoryController extends GetxController {
  final activities = <ActivityLog>[].obs;

  ActivityFirestoreService get _activityService =>
      Get.find<ActivityFirestoreService>();
  UserSessionController get _sessionController =>
      Get.find<UserSessionController>();
  BroilerController get _broilerController => Get.find<BroilerController>();

  final lastTick = DateTime.now().obs;
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _listenToActivities();

    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      lastTick.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  void _listenToActivities() {
    ever(_sessionController.userId, (String userId) {
      if (userId.isNotEmpty) {
        activities.bindStream(_activityService.watchActivities(userId: userId));
      } else {
        activities.clear();
      }
    });

    if (_sessionController.userId.value.isNotEmpty) {
      activities.bindStream(
        _activityService.watchActivities(
          userId: _sessionController.userId.value,
        ),
      );
    }
  }

  static Future<void> log({
    required String title,
    required String description,
    required ActivityType type,
    String? projectId,
  }) async {
    final history = Get.isRegistered<HistoryController>()
        ? Get.find<HistoryController>()
        : Get.put(HistoryController(), permanent: true);

    final userId = history._sessionController.userId.value;
    if (userId.isEmpty) return;

    final pId =
        projectId ?? history._broilerController.selectedProjectId.value ?? '';
    String pName = '';

    if (pId.isNotEmpty) {
      try {
        pName = history._broilerController.projects
            .firstWhere((p) => p.projectId == pId)
            .projectName;
      } catch (_) {
        pName = history._broilerController.projectNameController.text;
      }
    }

    final logEntry = ActivityLog(
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: type,
      projectId: pId,
      projectName: pName,
    );

    await history._activityService.logActivity(userId: userId, log: logEntry);
  }
}
