// 📄 ActivityLogAdminPage.dart (Improved UI + Responsive)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/theme/AppColor.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.timestamp,
  });
}

class ActivityLogAdminPage extends StatefulWidget {
  const ActivityLogAdminPage({Key? key}) : super(key: key);

  @override
  State<ActivityLogAdminPage> createState() => _ActivityLogAdminPageState();
}

class _ActivityLogAdminPageState extends State<ActivityLogAdminPage> {
  String? selectedUserId;
  DateTimeRange? selectedDateRange;

  List<ActivityLog> logs = [];
  List<String> users = ["All Users", "User A", "User B"];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    logs = [
      ActivityLog(
        id: 'log001',
        userId: 'u001',
        userName: 'User A',
        action: 'Logged in',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ActivityLog(
        id: 'log002',
        userId: 'u002',
        userName: 'User B',
        action: 'Deleted a book',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Activity Logs'),
        backgroundColor: AppColors.primary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      runSpacing: 12,
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                          child: DropdownButtonFormField<String>(
                            value: selectedUserId,
                            decoration: const InputDecoration(
                              labelText: "Filter by User",
                              border: OutlineInputBorder(),
                            ),
                            items: users.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (val) => setState(() => selectedUserId = val),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: const Text("Select Date"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: _loadLogs,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, tableConstraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                              child: DataTable(
                                columnSpacing: 32,
                                headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.1)),
                                columns: const [
                                  DataColumn(label: Text("Timestamp")),
                                  DataColumn(label: Text("User")),
                                  DataColumn(label: Text("Action")),
                                ],
                                rows: logs.map((log) => DataRow(cells: [
                                  DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp))),
                                  DataCell(Text(log.userName)),
                                  DataCell(Text(log.action)),
                                ])).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}