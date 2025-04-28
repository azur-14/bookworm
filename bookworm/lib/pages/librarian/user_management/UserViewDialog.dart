// /pages/user_management/widgets/user_view_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/User.dart';
import 'UserReadonlyField.dart';
import 'dart:convert';

class UserViewDialog extends StatelessWidget {
  final User user;

  const UserViewDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('MMM dd, yyyy').format(user.timeCreate);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (user.avatar.isNotEmpty)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: MemoryImage(base64Decode(user.avatar)),
                )
              else
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.brown,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              const SizedBox(height: 20),
              UserReadOnlyField(label: 'ID', value: user.id),
              UserReadOnlyField(label: 'Name', value: user.name),
              UserReadOnlyField(label: 'Email', value: user.email),
              UserReadOnlyField(label: 'Phone', value: user.phone),
              UserReadOnlyField(label: 'Role', value: user.role),
              UserReadOnlyField(label: 'Status', value: user.status),
              UserReadOnlyField(label: 'Created', value: formattedDate),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
