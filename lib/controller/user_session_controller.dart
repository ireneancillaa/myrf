import 'package:get/get.dart';

class UserSessionController extends GetxController {
  final userIdentifier = ''.obs;
  final userId = ''.obs; // Document ID dari Firestore users collection

  String get displayName {
    final value = userIdentifier.value.trim();
    if (value.isEmpty) return 'Breeder';

    if (value.contains('@')) {
      final parts = value.split('@');
      if (parts.first.trim().isNotEmpty) {
        return parts.first.trim();
      }
    }
    return value;
  }

  String get emailOrId {
    final value = userIdentifier.value.trim();
    return value.isEmpty ? '-' : value;
  }

  void setSession({required String identifier, required String id}) {
    userIdentifier.value = identifier.trim();
    userId.value = id.trim();
  }

  void clear() {
    userIdentifier.value = '';
    userId.value = '';
  }
}
