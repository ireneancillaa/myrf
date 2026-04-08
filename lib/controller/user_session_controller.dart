import 'package:get/get.dart';

class UserSessionController extends GetxController {
  final userIdentifier = ''.obs;

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

  void setLoginIdentifier(String value) {
    userIdentifier.value = value.trim();
  }

  void clear() {
    userIdentifier.value = '';
  }
}
