import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double contentWidth = maxWidth < 500 ? maxWidth : 400;
          final double horizontalPadding = maxWidth < 500 ? 16 : 24;
          final double verticalPadding = maxWidth < 500 ? 16 : 32;
          final double logoSize = maxWidth < 500 ? 90 : 120;
          final double logoRadius = maxWidth < 500 ? 20 : 28;
          final double logoImg = maxWidth < 500 ? 60 : 90;
          final double space1 = maxWidth < 500 ? 10 : 16;
          final double space2 = maxWidth < 500 ? 12 : 24;
          final double space3 = maxWidth < 500 ? 4 : 8;
          final double space4 = maxWidth < 500 ? 20 : 32;
          final double space5 = maxWidth < 500 ? 40 : 48;
          final double space6 = maxWidth < 500 ? 8 : 16;
          final double buttonHeight = maxWidth < 500 ? 40 : 48;

          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(logoRadius),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: logoImg,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: space1),
                      const Text(
                        'MYRF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const Text(
                        'Research Farm Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const Text(
                        'PT Charoen Pokphand Indonesia, Tbk',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: space5),
                      const Text(
                        'Masuk ke Akun Anda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: space2),
                      const Text(
                        'Email atau ID Karyawan',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: space3),
                      TextField(
                        controller: controller.emailController,
                        decoration: _inputDecoration(
                          'Masukkan email atau ID karyawan',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: space1),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: space3),
                      Obx(
                        () => TextField(
                          controller: controller.passwordController,
                          obscureText: controller.obscurePassword.value,
                          decoration: _inputDecoration('Masukkan password'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: space4),
                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: controller.login,
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: space1),
                      Center(
                        child: TextButton(
                          onPressed: controller.forgotPassword,
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: space5),
                      const Divider(color: Color(0xFFEEEEEE)),
                      SizedBox(height: space6),
                      const Text(
                        'PT Charoen Pokphand Indonesia, Tbk',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      const Text(
                        '© 2024 Charoen Pokphand Indonesia. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _footerButton(
                            'Syarat & Ketentuan',
                            controller.openTerms,
                          ),
                          const Text(
                            ' | ',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          _footerButton(
                            'Kebijakan Privasi',
                            controller.openPrivacy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
      ),
    );
  }

  Widget _footerButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF22C55E),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF22C55E),
        ),
      ),
    );
  }
}
