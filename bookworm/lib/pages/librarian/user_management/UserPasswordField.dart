// file: user_widgets/user_password_field.dart
import 'package:flutter/material.dart';
import 'dart:math';

class UserPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool passwordVisible;
  final VoidCallback toggleVisibility;

  const UserPasswordField({
    Key? key,
    required this.controller,
    required this.label,
    required this.passwordVisible,
    required this.toggleVisibility,
  }) : super(key: key);

  String generateRandomPassword(int length) {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random rnd = Random();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !passwordVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.brown[700]),
              onPressed: toggleVisibility,
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.brown[700]),
              onPressed: () {
                controller.text = generateRandomPassword(8);
              },
            ),
          ],
        ),
      ),
    );
  }
}
