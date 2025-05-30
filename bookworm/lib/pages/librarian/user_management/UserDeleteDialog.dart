import 'package:flutter/material.dart';
import 'package:bookworm/model/User.dart';
import 'package:bookworm/theme/AppColor.dart';

class UserDeleteDialog extends StatelessWidget {
  final User user;
  final VoidCallback onConfirmDelete;

  const UserDeleteDialog({
    Key? key,
    required this.user,
    required this.onConfirmDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground, // nền be nhạt
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        'Delete Confirmation',
        style: TextStyle(
          color: AppColors.primary,    // nâu đậm
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${user.email}"?',
        style: const TextStyle(color: Colors.black87),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary, // text nâu
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // nâu đậm
            foregroundColor: AppColors.white,    // text trắng
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            onConfirmDelete();
            Navigator.pop(context);
          },
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}
