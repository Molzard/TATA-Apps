import 'package:flutter/material.dart';

class AutoFillText {
  static void autoFillRegister1(
    TextEditingController emailController,
    TextEditingController noHpController,
    TextEditingController passwordController,
  ) {
    emailController.text = 'test@gmail.com';
    noHpController.text = '081234567890';
    passwordController.text = 'gatau123';
  }
}
