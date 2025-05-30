import 'package:flutter/material.dart';
import 'package:bookworm/model/User.dart';

import '../../../theme/AppColor.dart';

class UserTable extends StatelessWidget {
  final List<User> users;
  final void Function(User user) onView;
  final void Function(User user) onEdit;
  final void Function(User user) onDelete;

  const UserTable({
    Key? key,
    required this.users,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lọc bỏ admin nếu cần
    final displayUsers = users.where((u) => u.role != 'admin').toList();
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium;
    final cs = theme.colorScheme;

    return Card(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith((_) => cs.primary.withOpacity(0.1)),
            dataRowHeight: 56,
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: displayUsers.map((user) {
              return DataRow(cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(user.id, style: textStyle, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(user.name, style: textStyle)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(user.email, style: textStyle, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(user.phone, style: textStyle)),
                DataCell(Text(user.role, style: textStyle)),
                DataCell(Text(user.status, style: textStyle)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'View',
                      child: IconButton(
                        icon: Icon(Icons.visibility, color: cs.primary),
                        onPressed: () => onView(user),
                        splashRadius: 20,
                      ),
                    ),
                    Tooltip(
                      message: 'Edit',
                      child: IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => onEdit(user),
                        splashRadius: 20,
                      ),
                    ),
                    Tooltip(
                      message: 'Delete',
                      child: IconButton(
                        icon: Icon(Icons.delete, color: cs.error),
                        onPressed: () => onDelete(user),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
