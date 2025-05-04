// lib/pages/BookingReviewPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookingReviewPage extends StatefulWidget {
  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtl = TextEditingController();
  List<RoomBookingRequest> _allRequests = [];
  String _adminId = 'unknown_admin';

  // Lọc lịch sử
  String _historyFilter = 'Tất cả';
  DateTime _historyDate = DateTime.now();
  int _historyYear = DateTime.now().year;
  int _historyMonth = DateTime.now().month;
  int _historyQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  String _statsFilter = 'Tất cả';
  static const List<String> _statsFilterOptions = [
    'Tất cả',
    'Yêu cầu',        // pending
    'Đã duyệt',       // approved
    // paid
    'Đang sử dụng',   // using
    'Hoàn thành', //completed
    'Từ chối',        // rejected
    'Đã hủy',         // cancelled
  ];
  static const Map<String, String> _labelToStatus = {
    'Yêu cầu':       'pending',
    'Đã duyệt':      'approved',
    'Đang sử dụng':  'using',
    'Hoàn thành': 'finished',
    'Từ chối':       'rejected',
    'Đã hủy':        'cancelled',
  };
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _adminId = prefs.getString('userId') ?? 'unknown_admin';
    });
    _loadRequests();
    _searchCtl.addListener(() => setState(() {}));
  }
  static const _tabs = [
    {'status': 'pending',   'label': 'Yêu cầu'},
    {'status': 'approved',  'label': 'Đã duyệt'},
    {'status': 'using',     'label': 'Đang sử dụng'},
    {'status': 'rejected',  'label': 'Từ chối'},
    {'status': 'cancelled', 'label': 'Đã hủy'},
    {'status': 'stats',     'label': 'Thống kê'},
  ];
  Future<void> _loadRequests() async {
    try {
      final list = await fetchRoomBookingRequests();
      setState(() => _allRequests = list);
    } catch (e) {
      debugPrint('Lỗi khi tải yêu cầu: $e');
    }
  }

  Future<List<RoomBookingRequest>> fetchRoomBookingRequests() async {
    final url = Uri.parse('http://localhost:3002/api/roomBookingRequest');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => RoomBookingRequest.fromJson(e)).toList();
    }
    throw Exception('Lỗi khi tải RoomBookingRequest');
  }

  Future<Bill> _createBill(Bill bill) async {
    final url = Uri.parse('http://localhost:3002/api/bills');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bill.toJson()),
    );
    if (res.statusCode == 201) {
      return Bill.fromJson(json.decode(res.body));
    }
    throw Exception('Lỗi khi tạo hóa đơn: ${res.body}');
  }

  void _showInvoiceDialog(RoomBookingRequest req) {
    final now = DateTime.now();
    final overdueDays =
    now.isAfter(req.endTime) ? now.difference(req.endTime).inDays : 0;
    final overdueFee = overdueDays * 10000; // 10k/ngày
    final double damageFee = req.purpose.contains('hư hỏng') ? 50000 : 0;
    final double totalFee = overdueFee + damageFee;

    final amountCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thanh toán & Hóa đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yêu cầu ID: ${req.id}'),
            const SizedBox(height: 8),
            Text(
                'Thời gian: ${DateFormat('yyyy-MM-dd HH:mm').format(req.startTime)} → ${DateFormat('HH:mm').format(req.endTime)}'),
            const Divider(),
            Text('Quá hạn: $overdueDays ngày → ${overdueFee}₫'),
            Text('Phí hư hỏng: ${damageFee}₫'),
            const Divider(),
            Text('TỔNG: ${totalFee}₫',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtl,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: 'Khách thanh toán (₫)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final paid = double.tryParse(amountCtl.text.trim()) ?? 0;
              final change = paid - totalFee;
              final bill = Bill(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                requestId: req.id,
                type: 'room',
                overdueDays: overdueDays,
                overdueFee: overdueFee,
                damageFee: damageFee,
                totalFee: totalFee,
                amountReceived: paid,
                changeGiven: change < 0 ? 0 : change,
              );
              try {
                final created = await _createBill(bill);
                await _logAction(
                  adminId: _adminId,
                  actionType: 'CREATE',
                  targetType: 'Bill',
                  targetId: created.id,
                  description: 'Xuất hóa đơn cho booking ${req.id}, tổng tiền: ${created.totalFee}₫',
                );
                Navigator.pop(context);
                _showBillPreview(created);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi tạo hóa đơn: $e')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showBillPreview(Bill bill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hóa đơn đã xuất'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã hóa đơn: ${bill.id}'),
            Text('Yêu cầu: ${bill.requestId}'),
            Text('Ngày: ${DateFormat('yyyy-MM-dd – kk:mm').format(bill.date)}'),
            const Divider(),
            Text('Quá hạn: ${bill.overdueDays} ngày → ${bill.overdueFee}₫'),
            Text('Hư hỏng: ${bill.damageFee}₫'),
            const Divider(),
            Text('Tổng: ${bill.totalFee}₫',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Khách trả: ${bill.amountReceived}₫'),
            Text('Tiền thối: ${bill.changeGiven}₫'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  List<RoomBookingRequest> get _pending =>
      _allRequests.where((r) => r.status == 'pending').toList();

  List<RoomBookingRequest> get _ongoing {
    final now = DateTime.now();
    return _allRequests
        .where((r) => r.status == 'approved' && r.endTime.isAfter(now))
        .toList();
  }

  List<RoomBookingRequest> get _past {
    final now = DateTime.now();
    return _allRequests
        .where((r) =>
    (r.status == 'approved' && r.endTime.isBefore(now)) ||
        r.status == 'rejected')
        .toList();
  }

  List<RoomBookingRequest> get _filteredPast {
    switch (_historyFilter) {
      case 'Ngày':
        return _past
            .where((r) =>
        r.startTime.year == _historyDate.year &&
            r.startTime.month == _historyDate.month &&
            r.startTime.day == _historyDate.day)
            .toList();
      case 'Tháng':
        return _past
            .where((r) =>
        r.startTime.year == _historyYear &&
            r.startTime.month == _historyMonth)
            .toList();
      case 'Quý':
        return _past
            .where((r) {
          final q = ((r.startTime.month - 1) ~/ 3) + 1;
          return r.startTime.year == _historyYear && q == _historyQuarter;
        })
            .toList();
      case 'Năm':
        return _past
            .where((r) => r.startTime.year == _historyYear)
            .toList();
      default:
        return _past;
    }
  }

  bool _hasConflict(RoomBookingRequest req) {
    return _allRequests.any((a) =>
    a.status == 'approved' &&
        a.roomId == req.roomId &&
        a.id != req.id &&
        a.startTime.isBefore(req.endTime) &&
        a.endTime.isAfter(req.startTime));
  }

  Future<void> _updateStatus(RoomBookingRequest r, String newStatus) async {
    final url = Uri.parse(
        'http://localhost:3002/api/roomBookingRequest/${r.id}');
    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': newStatus}),
    );
    if (res.statusCode == 200) {
      setState(() => r.status = newStatus);

      // Ghi log hành động
      await _logAction(
        adminId: _adminId,
        actionType: 'UPDATE',
        targetType: 'RoomBookingRequest',
        targetId: r.id,
        description: 'Cập nhật trạng thái thành "${newStatus}" cho booking phòng ${r.roomId}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trạng thái đã chuyển → ${newStatus.toUpperCase()}'),
          backgroundColor: _badgeColor(newStatus),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final filter = _searchCtl.text.toLowerCase();

    return DefaultTabController(
      length: _tabs.length, // =7
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Quản lý đặt phòng', style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _tabs.map((t) => Tab(text: t['label']!)).toList(),
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: 'Tìm phòng hoặc user...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Nội dung theo tab
            Expanded(
              child: TabBarView(
                children: _tabs.map((t) {
                  final key = t['status']!;

                  // Tab “Thống kê”
                  if (key == 'stats') {
                    // 1. Summary
                    final total = _allRequests.length;
                    final byStatus = {
                      for (var tt in _tabs.where((e) => e['status'] != 'stats'))
                        tt['status']!: _allRequests.where((r) => r.status == tt['status']).length
                    };

                    // 2. Lấy toàn bộ history rồi lọc
                    final rawHistory = List<RoomBookingRequest>.from(_allRequests);
                    final filteredHistory = (_statsFilter == 'Tất cả')
                        ? rawHistory
                        : rawHistory.where((r) => r.status == _labelToStatus[_statsFilter]).toList();

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tổng quan
                          Text('Tổng booking: $total',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...byStatus.entries.map((e) {
                            final label = _tabs.firstWhere((tt) => tt['status'] == e.key)['label'];
                            return Text('$label: ${e.value}', style: const TextStyle(fontSize: 16));
                          }),
                          const Divider(height: 32),

                          // Dropdown lọc lịch sử
                          DropdownButtonFormField<String>(
                            value: _statsFilter,
                            decoration: InputDecoration(
                              labelText: 'Lọc lịch sử',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            items: _statsFilterOptions
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => _statsFilter = v!),
                          ),
                          const SizedBox(height: 16),

                          // Danh sách lịch sử sau lọc
                          Expanded(
                            child: filteredHistory.isEmpty
                                ? const Center(child: Text('Không có lịch sử phù hợp.'))
                                : ListView.builder(
                              itemCount: filteredHistory.length,
                              itemBuilder: (ctx, i) => _buildCardForStatus(filteredHistory[i]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Các tab booking bình thường
                  final list = _allRequests.where((r) {
                    final matchStatus = r.status == key;
                    final matchSearch = filter.isEmpty
                        || r.roomId.toLowerCase().contains(filter)
                        || r.userId.toLowerCase().contains(filter);
                    return matchStatus && matchSearch;
                  }).toList();

                  if (list.isEmpty) {
                    return Center(child: Text('Không có: ${t['label']}'));
                  }
                  return ListView(
                    children: list.map(_buildCardForStatus).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trả về màu badge theo status, thêm 'finished'
  Color _badgeColor(String status) {
    switch (status) {
      case 'approved':   return Colors.orange;
      case 'pending':    return AppColors.primary;
      case 'using':      return Colors.green;
      case 'finished':   return Colors.blueGrey;
      case 'cancelled':  return Colors.red;
      case 'rejected':   return Colors.red;
      default:           return Colors.grey;
    }
  }

  Widget _buildCardForStatus(RoomBookingRequest r) {
    final now = DateTime.now();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final actions = <Widget>[];

    // Xác định xem quá hạn chưa (chỉ áp dụng khi đang sử dụng)
    final bool isOverdue = r.status == 'using' && now.isAfter(r.endTime);

    // Chọn màu nền & viền
    final Color cardColor   = isOverdue ? Colors.red.shade50 : AppColors.white;
    final Color borderColor = isOverdue ? Colors.red : _badgeColor(r.status);

    switch (r.status) {
      case 'pending':
        actions.addAll([
          ElevatedButton(
            onPressed: () => _updateStatus(r, 'approved'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _updateStatus(r, 'rejected'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Reject'),
          ),
        ]);
        break;

      case 'approved':
        actions.addAll([
          OutlinedButton(
            onPressed: () => _updateStatus(r, 'cancelled'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _updateStatus(r, 'using'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Thanh toán'),
          ),
        ]);
        break;

      case 'using':
        actions.add(
          ElevatedButton(
            onPressed: () => _updateStatus(r, 'finished'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        );
        break;

      default:
        break;
    }

    return Card(
      color: cardColor, // dùng màu nền động
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Room ID + badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.roomId,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.status.toUpperCase(),
                    style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text('${dateFmt.format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}'),
            const SizedBox(height: 4),
            Text('User: ${r.userId}'),
            Text('Mục đích: ${r.purpose}'),

            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: actions),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _logAction({
    required String adminId,
    required String actionType,
    required String targetType,
    required String targetId,
    required String description,
  }) async {
    final url = Uri.parse('http://localhost:3004/api/logs');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'adminId': adminId,
        'actionType': actionType,
        'targetType': targetType,
        'targetId': targetId,
        'description': description,
      }),
    );
  }
}
