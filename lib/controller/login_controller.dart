import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_session_controller.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;
  final isLoading = false.obs;

  late final UserSessionController _sessionController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Login Failed', 'Email and password are required');
      return;
    }

    isLoading.value = true;
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        _sessionController.setSession(identifier: email, id: userDoc.id);
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Login Failed', 'Invalid email or password');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during login: $e');
    } finally {
      isLoading.value = false;
    }
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
