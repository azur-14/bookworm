import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String userName;
  final String userRole;
  final String formattedTime;
  final String formattedDate;

  const TopBar({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.formattedTime,
    required this.formattedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: user info (name and role)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: const TextStyle(fontSize: 16)),
              Text(userRole, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          // Right side: time and date
          Row(
            children: [
              Text(
                formattedTime,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(width: 16),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
