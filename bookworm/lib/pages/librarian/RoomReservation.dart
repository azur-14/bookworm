import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/RequestStatusHistory.dart';

class BookingReviewPage extends StatefulWidget {
  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtl = TextEditingController();
  List<RoomBookingRequest> _allRequests = [];
  String _adminId = 'unknown_admin';
  String _sortBy = 'startTime'; // Tiêu chí sắp xếp: startTime, endTime, roomId, userId
  bool _sortAscending = true; // Hướng sắp xếp: true (tăng dần), false (giảm dần)

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _adminId = prefs.getString('userId') ?? 'unknown_admin';
    });
    _loadRequests();
    _searchCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  static const _tabs = [
    {'status': 'pending', 'label': 'Yêu cầu'},
    {'status': 'approved', 'label': 'Đã duyệt'},
    {'status': 'using', 'label': 'Đang sử dụng'},
    {'status': 'rejected', 'label': 'Từ chối'},
    {'status': 'cancelled', 'label': 'Đã hủy'},
    {'status': 'stats', 'label': 'Thống kê'},
  ];

  Future<void> _loadRequests() async {
    try {
      final list = await fetchRoomBookingRequests();
      setState(() => _allRequests = list);
    } catch (e) {
      debugPrint('Lỗi khi tải yêu cầu: $e');
    }
  }

  /// Hiển thị dialog lịch sử thay đổi status cho booking request

// 1. History Dialog
  Future<void> _showHistoryDialog(String requestId) async {
    try {
      final url = Uri.parse('http://localhost:3002/api/requestStatusHistory/$requestId');
      final res = await http.get(url);
      if (res.statusCode != 200) throw Exception(res.body);
      final data = (json.decode(res.body) as List)
          .map((e) => RequestStatusHistory.fromJson(e))
          .toList();

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Lịch sử thay đổi: $requestId',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: data.isEmpty
                      ? Center(child: Text('Chưa có lịch sử thay đổi.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final h = data[i];
                      final time = DateFormat('yyyy-MM-dd HH:mm').format(h.changeTime);
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.history, color: AppColors.primary),
                          title: Text(
                            '${h.oldStatus} → ${h.newStatus}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lúc: $time'),
                              Text('Bởi: ${h.changedBy}'),
                              if (h.reason.isNotEmpty) Text('Lý do: ${h.reason}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được lịch sử: $e')),
      );
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

  Future<void> _postBill(Bill bill) async {
    final url = Uri.parse('http://localhost:3002/api/bill');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': bill.id,
        'borrowRequestId': bill.requestId,
        'type': bill.type,
        'overdueDays': bill.overdueDays,
        'overdueFee': bill.overdueFee,
        'damageFee': bill.damageFee,
        'totalFee': bill.totalFee,
        'amountReceived': bill.amountReceived,
        'changeGiven': bill.changeGiven,
        'date': bill.date.toIso8601String(),
      }),
    );
    if (response.statusCode == 201) {
      debugPrint('Gửi bill thành công!');
    } else {
      debugPrint('Lỗi gửi bill: ${response.statusCode} ${response.body}');
    }
  }

  // 2. Invoice Dialog
  Future<void> _showInvoiceDialog(RoomBookingRequest req) async {
    final now = DateTime.now();
    final minutes = req.endTime.difference(req.startTime).inMinutes;
    final hours = minutes / 60.0;
    final pricePerHour = req.pricePerHour ?? 0.0;
    final base = hours * pricePerHour;
    final overdueDays = now.isAfter(req.endTime) ? now.difference(req.endTime).inDays : 0;
    final overdueFee = overdueDays * 10000;
    final damageFee = req.purpose?.contains('hư hỏng') == true ? 50000.0 : 0.0;
    final total = base + overdueFee + damageFee;
    final amountCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('Thanh toán & Hóa đơn', style: Theme.of(context).textTheme.titleLarge),
              ),
              SizedBox(height: 16),
              Table(
                columnWidths: {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
                children: [
                  _buildRow('Yêu cầu ID', req.id),
                  _buildRow(
                    'Thời gian',
                    '${DateFormat('yyyy-MM-dd HH:mm').format(req.startTime)} → ${DateFormat('HH:mm').format(req.endTime)}',
                  ),
                  _buildRow('Giờ sử dụng', '${hours.toStringAsFixed(2)}h'),
                  _buildRow('Phí/giờ', '${pricePerHour.toStringAsFixed(0)}₫'),
                  _buildRow('Tạm tính', '${base.toStringAsFixed(0)}₫'),
                  _buildRow('Quá hạn', '$overdueDays ngày → ${overdueFee.toStringAsFixed(0)}₫'),
                  _buildRow('Hư hỏng', '${damageFee.toStringAsFixed(0)}₫'),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('TỔNG', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('${total.toStringAsFixed(0)}₫', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountCtl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Khách thanh toán (₫)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final paid = double.tryParse(amountCtl.text.trim()) ?? 0;
                      final change = paid - total;
                      final bill = Bill(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        requestId: req.id,
                        type: 'room',
                        date: now,
                        overdueDays: overdueDays,
                        overdueFee: overdueFee,
                        damageFee: damageFee,
                        totalFee: total,
                        amountReceived: paid,
                        changeGiven: change < 0 ? 0 : change,
                      );
                      try {
                        await _postBill(bill);
                        await _updateStatus(req, 'using');
                        Navigator.pop(context);
                        _showBillPreview(bill);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi tạo hóa đơn: $e')),
                        );
                      }
                    },
                    child: Text('Xác nhận'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(String label, String value) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(value),
      ),
    ]);
  }


// 3. Bill Preview Dialog
  void _showBillPreview(Bill bill) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('Hóa đơn đã xuất', style: Theme.of(context).textTheme.titleLarge),
              ),
              SizedBox(height: 16),
              Table(
                columnWidths: {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
                children: [
                  _buildRow('Mã hóa đơn', bill.id),
                  _buildRow('Yêu cầu', bill.requestId),
                  _buildRow('Ngày', DateFormat('yyyy-MM-dd – HH:mm').format(bill.date)),
                  _buildRow('Quá hạn', '${bill.overdueDays} ngày → ${bill.overdueFee}₫'),
                  _buildRow('Hư hỏng', '${bill.damageFee?.toStringAsFixed(0) ?? '0'}₫'),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Tổng', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('${bill.totalFee?.toStringAsFixed(0) ?? '0'}₫', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  _buildRow('Khách trả', '${bill.amountReceived?.toStringAsFixed(0) ?? '0'}₫'),
                  _buildRow('Tiền thối', '${bill.changeGiven?.toStringAsFixed(0) ?? '0'}₫'),
                ],
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
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
    return _applySortAndFilter(_past);
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
    final url = Uri.parse('http://localhost:3002/api/roomBookingRequest/${r.id}');
    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': newStatus}),
    );
    if (res.statusCode == 200) {
      await http.post(
        Uri.parse('http://localhost:3002/api/requestStatusHistory'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requestId': r.id,
          'requestType': 'room',
          'oldStatus': r.status,
          'newStatus': newStatus,
          'changedBy': _adminId,
          'reason': 'Cập nhật từ UI BookingReviewPage'
        }),
      );

      setState(() => r.status = newStatus);

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

  List<RoomBookingRequest> _applySortAndFilter(List<RoomBookingRequest> list) {
    // Lọc theo search
    var filtered = list.where((r) {
      final matchSearch = _searchCtl.text.isEmpty ||
          r.roomId.toLowerCase().contains(_searchCtl.text.toLowerCase()) ||
          r.userId.toLowerCase().contains(_searchCtl.text.toLowerCase());
      return matchSearch;
    }).toList();

    // Sắp xếp
    filtered.sort((a, b) {
      int compare;
      switch (_sortBy) {
        case 'roomId':
          compare = a.roomId.compareTo(b.roomId);
          break;
        case 'userId':
          compare = a.userId.compareTo(b.userId);
          break;
        case 'endTime':
          compare = a.endTime.compareTo(b.endTime);
          break;
        case 'startTime':
        default:
          compare = a.startTime.compareTo(b.startTime);
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
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
            // Search bar & Sort controls
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtl,
                    decoration: InputDecoration(
                      hintText: 'Tìm phòng hoặc user...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Dropdown cho sortBy
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: InputDecoration(
                            labelText: 'Sắp xếp theo',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'startTime', child: Text('Thời gian bắt đầu')),
                            DropdownMenuItem(value: 'endTime', child: Text('Thời gian kết thúc')),
                            DropdownMenuItem(value: 'roomId', child: Text('ID Phòng')),
                            DropdownMenuItem(value: 'userId', child: Text('ID Người dùng')),
                          ],
                          onChanged: (v) => setState(() => _sortBy = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút toggle hướng sắp xếp
                      IconButton(
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => _sortAscending = !_sortAscending),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

                    // 2. Lấy toàn bộ lịch sử và áp dụng tìm kiếm + sắp xếp
                    final sortedHistory = _applySortAndFilter(_allRequests);

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
                          // Danh sách lịch sử
                          Expanded(
                            child: sortedHistory.isEmpty
                                ? const Center(child: Text('Không có lịch sử phù hợp.'))
                                : ListView.builder(
                              itemCount: sortedHistory.length,
                              itemBuilder: (ctx, i) {
                                final req = sortedHistory[i];
                                return GestureDetector(
                                  onTap: () => _showHistoryDialog(req.id),
                                  child: _buildCardForStatus(req),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Các tab booking bình thường
                  final list = _allRequests.where((r) => r.status == key).toList();
                  final sortedList = _applySortAndFilter(list);

                  if (sortedList.isEmpty) {
                    return Center(child: Text('Không có: ${t['label']}'));
                  }
                  return ListView(
                    children: sortedList.map(_buildCardForStatus).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trả về màu badge theo status
  Color _badgeColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.orange;
      case 'pending':
        return AppColors.primary;
      case 'using':
        return Colors.green;
      case 'finished':
        return Colors.blueGrey;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCardForStatus(RoomBookingRequest r) {
    final now = DateTime.now();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final actions = <Widget>[];

    // Xác định xem quá hạn chưa (chỉ áp dụng khi đang sử dụng)
    final bool isOverdue = r.status == 'using' && now.isAfter(r.endTime);
    // Kiểm tra xung đột
    final bool hasConflict = _hasConflict(r);

    // Chọn màu nền & viền
    final Color cardColor = isOverdue
        ? Colors.red.shade50
        : hasConflict
        ? Colors.red.shade50 // Màu đỏ nhạt cho xung đột
        : AppColors.white;
    final Color borderColor = isOverdue
        ? Colors.red
        : hasConflict
        ? Colors.red.shade700 // Viền đỏ đậm cho xung đột
        : _badgeColor(r.status);

    switch (r.status) {
      case 'pending':
        actions.addAll([
          ElevatedButton(
            onPressed: hasConflict
                ? null // Vô hiệu hóa nút nếu có xung đột
                : () => _updateStatus(r, 'approved'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown,foregroundColor: AppColors.cardBackground),
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
            onPressed: () => _showInvoiceDialog(r),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        );
        break;

      default:
        break;
    }

    return Card(
      color: cardColor,
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
            // Header: Room ID + badge + conflict warning
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
            if (hasConflict) ...[
              const SizedBox(height: 8),
              Text(
                'Cảnh báo: Xung đột thời gian với booking khác!',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
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
