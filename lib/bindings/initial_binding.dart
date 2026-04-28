import 'package:get/get.dart';
import '../controller/broiler_controller.dart';
import '../controller/history_controller.dart';
import '../controller/user_session_controller.dart';
import '../services/broiler_firestore_service.dart';
import '../services/activity_firestore_service.dart';
import '../services/monitoring_firestore_service.dart';
import '../services/config_firestore_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services
    Get.put(UserSessionController(), permanent: true);
    Get.put(BroilerFirestoreService(), permanent: true);
    Get.put(ActivityFirestoreService(), permanent: true);
    Get.put(MonitoringFirestoreService(), permanent: true);
    Get.put(ConfigFirestoreService(), permanent: true);

    // 2. Main Controllers
    Get.put(BroilerController(), permanent: true);
    Get.put(HistoryController(), permanent: true);
  }
}
