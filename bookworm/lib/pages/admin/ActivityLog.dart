import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActivityLog {
  final String id;
  final String adminId;
  final String actionType;
  final String targetType;
  final String targetId;
  final String description;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.adminId,
    required this.actionType,
    required this.targetType,
    required this.targetId,
    required this.description,
    required this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? json['_id'],
      adminId: json['adminId'],
      actionType: json['actionType'],
      targetType: json['targetType'],
      targetId: json['targetId'],
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'actionType': actionType,
      'targetType': targetType,
      'targetId': targetId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
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
                                  DataColumn(label: Text("Thời gian")),
                                  DataColumn(label: Text("Người thực hiện")),
                                  DataColumn(label: Text("Hành động")),
                                  DataColumn(label: Text("Đối tượng")),
                                  DataColumn(label: Text("Mô tả")),
                                ],
                                rows: logs.map((log) => DataRow(cells: [
                                  DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp))),
                                  DataCell(Text(log.adminId)),
                                  DataCell(Text(log.actionType)),
                                  DataCell(Text('${log.targetType} (${log.targetId})')),
                                  DataCell(Text(log.description)),
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

  Future<List<ActivityLog>> fetchAllActivityLogs() async {
    final uri = Uri.parse('http://localhost:3004/api/logs');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => ActivityLog.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải activity logs: ${response.body}');
    }
  }

  void _loadLogs() async {
    try {
      final data = await fetchAllActivityLogs();
      setState(() => logs = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải logs: $e')),
      );
    }
  }

}