import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'user_session_controller.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;
  late final UserSessionController _sessionController;

  @override
  void onInit() {
    super.onInit();
    _sessionController = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);
  }

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void login() {
    final emailOrId = emailController.text.trim();
    final password = passwordController.text;

    if (emailOrId.isEmpty || password.isEmpty) {
      Get.snackbar('Login Failed', 'Email/ID and password are required');
      return;
    }

    _sessionController.setLoginIdentifier(emailOrId);
    Get.offAllNamed('/home');
  }

  void forgotPassword() {
    // TODO: Implement forgot password
    Get.snackbar(
      'Forgot Password',
      'Forgot password feature is not implemented yet',
    );
  }

  void openTerms() {
    // TODO: Navigate to Terms & Conditions page
    Get.snackbar('Terms & Conditions', 'Navigate to Terms & Conditions page');
  }

  void openPrivacy() {
    // TODO: Navigate to Privacy Policy page
    Get.snackbar('Privacy Policy', 'Navigate to Privacy Policy page');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
