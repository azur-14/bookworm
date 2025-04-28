// file: user_widgets/user_text_field.dart
import 'package:flutter/material.dart';

class UserTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool numericOnly;
  final ValueChanged<String>? onChanged;

  const UserTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.numericOnly = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: numericOnly ? TextInputType.number : TextInputType.text,
    );
  }
}
