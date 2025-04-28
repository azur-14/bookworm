// /pages/user_management/widgets/user_readonly_field.dart
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class UserReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const UserReadOnlyField({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: AutoSizeText(
              '$label:',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
          ),
          Expanded(
            child: AutoSizeText(
              value,
              maxLines: 1,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
