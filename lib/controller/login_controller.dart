import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void login() {
    // TODO: Implementasi login
    Get.snackbar('Login', 'Fitur login belum diimplementasikan');
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
