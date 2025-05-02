// /pages/user_management/widgets/user_table.dart
import 'package:flutter/material.dart';
import 'package:bookworm/model/User.dart';

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
    List<User> displayUsers = users.where((user) => user.role != 'admin').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: displayUsers.map((user) {
                return DataRow(
                  cells: [
                    DataCell(Text(user.id)),
                    DataCell(Text(user.name, overflow: TextOverflow.ellipsis)),
                    DataCell(Text(user.email)),
                    DataCell(Text(user.phone)),
                    DataCell(Text(user.role)),
                    DataCell(Text(user.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () {
                              Future.microtask(() {
                                onView(user);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.brown),
                            onPressed: () {
                              Future.microtask(() {
                                onEdit(user);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Future.microtask(() {
                                onDelete(user);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
