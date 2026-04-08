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
      Get.snackbar('Login Gagal', 'Email/ID dan password wajib diisi');
      return;
    }

    _sessionController.setLoginIdentifier(emailOrId);
    Get.offAllNamed('/home');
  }

  void forgotPassword() {
    // TODO: Implementasi lupa password
    Get.snackbar(
      'Lupa Password',
      'Fitur lupa password belum diimplementasikan',
    );
  }

  void openTerms() {
    // TODO: Navigasi ke halaman Syarat & Ketentuan
    Get.snackbar(
      'Syarat & Ketentuan',
      'Navigasi ke halaman Syarat & Ketentuan',
    );
  }

  void openPrivacy() {
    // TODO: Navigasi ke halaman Kebijakan Privasi
    Get.snackbar('Kebijakan Privasi', 'Navigasi ke halaman Kebijakan Privasi');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
