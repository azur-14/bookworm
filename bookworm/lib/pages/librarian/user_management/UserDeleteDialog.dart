// /pages/user_management/widgets/user_delete_dialog.dart
import 'package:flutter/material.dart';
import 'package:bookworm/model/User.dart';

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
      title: const Text('Delete Confirmation'),
      content: Text('Are you sure you want to delete "${user.email}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
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
