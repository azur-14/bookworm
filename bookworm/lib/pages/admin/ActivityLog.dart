import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActivityLog {
  final String id, adminId, actionType, targetType, targetId, description;
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
  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id'] ?? json['_id'],
    adminId: json['adminId'],
    actionType: json['actionType'],
    targetType: json['targetType'],
    targetId: json['targetId'],
    description: json['description'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ActivityLogAdminPage extends StatefulWidget {
  const ActivityLogAdminPage({Key? key}) : super(key: key);
  @override
  _ActivityLogAdminPageState createState() => _ActivityLogAdminPageState();
}

class _ActivityLogAdminPageState extends State<ActivityLogAdminPage> {
  String _selectedUser = 'All Users';
  DateTimeRange? _selectedRange;
  List<ActivityLog> _logs = [];
  final List<String> _users = ['All Users', 'User A', 'User B'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedRange = picked);
  }

  Future<void> _loadLogs() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3004/api/logs'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() => _logs = data.map((e) => ActivityLog.fromJson(e)).toList());
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải logs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter client-side
    final filtered = _logs.where((log) {
      final matchUser = _selectedUser == 'All Users' || log.adminId == _selectedUser;
      final matchDate = _selectedRange == null ||
          (log.timestamp.isAfter(_selectedRange!.start.subtract(const Duration(seconds:1))) &&
              log.timestamp.isBefore(_selectedRange!.end.add(const Duration(seconds:1))));
      return matchUser && matchDate;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Logs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ─── FILTER BAR ─────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // User dropdown
                    DropdownButton<String>(
                      value: _selectedUser,
                      items: _users
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUser = v!),
                    ),
                    const SizedBox(width: 24),
                    // Date range picker
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _selectedRange == null
                            ? 'Chọn khoảng thời gian'
                            : '${DateFormat('yyyy/MM/dd').format(_selectedRange!.start)} – ${DateFormat('yyyy/MM/dd').format(_selectedRange!.end)}',
                      ),
                      onPressed: _pickDateRange,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      color: AppColors.primary,
                      tooltip: 'Làm mới',
                      onPressed: _loadLogs,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── DATA TABLE ────────────────────────
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  AppColors.primary.withOpacity(0.1),
                                ),
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text('Thời gian')),
                                  DataColumn(label: Text('Người thực hiện')),
                                  DataColumn(label: Text('Hành động')),
                                  DataColumn(label: Text('Đối tượng')),
                                  DataColumn(label: Text('Mô tả')),
                                ],
                                // trong builder DataTable:
                                rows: List.generate(filtered.length, (i) {
                                  final log = filtered[i];
                                  final bg = i.isEven ? Colors.grey[50] : Colors.white;
                                  return DataRow(
                                    color: MaterialStateProperty.all(bg),  // <— mỗi DataRow có màu riêng
                                    cells: [
                                      DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp))),
                                      DataCell(Text(log.adminId)),
                                      DataCell(Text(log.actionType)),
                                      DataCell(Text('${log.targetType} (${log.targetId})')),
                                      DataCell(
                                        Container(
                                          width: 200,
                                          child: Text(log.description, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
