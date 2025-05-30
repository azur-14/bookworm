import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/User.dart';
import 'package:bookworm/theme/AppColor.dart';

class UserViewDialog extends StatelessWidget {
  final User user;
  const UserViewDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(user.timeCreate);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user.avatar.isNotEmpty
                      ? MemoryImage(base64Decode(user.avatar))
                      : null,
                  child: user.avatar.isEmpty
                      ? Icon(Icons.person, size: 40, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(height: 16),

                // Divider
                const Divider(height: 1),

                // Thông tin user
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    children: [
                      _buildTile('ID', user.id),
                      _buildTile('Name', user.name),
                      _buildTile('Email', user.email),
                      _buildTile('Phone', user.phone),
                      _buildTile('Role', user.role),
                      _buildTile('Status', user.status),
                      _buildTile('Created', formattedDate),
                    ],
                  ),
                ),

                // Nút Close
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white, // text màu trắng
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(bottom: 4),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
      subtitle: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}

