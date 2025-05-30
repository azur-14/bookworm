import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bookworm/theme/AppColor.dart';

class UserTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool numericOnly;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const UserTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.numericOnly = false,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: numericOnly
          ? TextInputType.number
          : TextInputType.text,
      inputFormatters: numericOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIcon: numericOnly
            ? const Icon(Icons.dialpad, color: AppColors.primary)
            : null,
      ),
    );
  }
}
