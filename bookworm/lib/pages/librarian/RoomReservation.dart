// lib/pages/BookingReviewPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingReviewPage extends StatefulWidget {
  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtl = TextEditingController();
  List<RoomBookingRequest> _allRequests = [];

  // Lọc lịch sử
  String _historyFilter = 'Tất cả';
  DateTime _historyDate = DateTime.now();
  int _historyYear = DateTime.now().year;
  int _historyMonth = DateTime.now().month;
  int _historyQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _searchCtl.addListener(() => setState(() {}));
  }

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
    final damageFee = req.purpose.contains('hư hỏng') ? 50000 : 0;
    final totalFee = overdueFee + damageFee;

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
              final paid = int.tryParse(amountCtl.text.trim()) ?? 0;
              final change = paid - totalFee;
              final bill = Bill(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                borrowRequestId: req.id,
                overdueDays: overdueDays,
                overdueFee: overdueFee,
                damageFee: damageFee,
                totalFee: totalFee,
                amountReceived: paid,
                changeGiven: change < 0 ? 0 : change,
              );
              try {
                final created = await _createBill(bill);
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
            Text('Yêu cầu: ${bill.borrowRequestId}'),
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

  Color _badgeColor(String st) {
    switch (st) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRequestCard(RoomBookingRequest r) {
    final conflict = _hasConflict(r);
    return Card(
      color: conflict ? Colors.red.shade50 : AppColors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: conflict ? Colors.red : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(r.roomId,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: _badgeColor(r.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.status.toUpperCase(),
                  style: TextStyle(
                      color: _badgeColor(r.status),
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('yyyy-MM-dd HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
          ),
          const SizedBox(height: 4),
          Text('User: ${r.userId}'),
          Text('Mục đích: ${r.purpose}'),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(
              onPressed: conflict ? null : () => _updateStatus(r, 'approved'),
              child: const Text('Approve'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _updateStatus(r, 'rejected'),
              child: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildOngoingCard(RoomBookingRequest r) {
    return Card(
      color: Colors.brown.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(r.roomId,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ONGOING',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('yyyy-MM-dd HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
          ),
          const SizedBox(height: 4),
          Text('User: ${r.userId}'),
          Text('Mục đích: ${r.purpose}'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _updateStatus(r, 'cancelled'),
            child: const Text('Cancel'),
          ),
        ]),
      ),
    );
  }

  Widget _buildPastCard(RoomBookingRequest r) {
    final isRejected = r.status == 'rejected';
    final badgeLabel = isRejected ? 'REJECTED' : 'PAST';
    final badgeColor = isRejected ? Colors.red : Colors.grey;

    return Card(
      color: isRejected ? Colors.red.shade50 : AppColors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: badgeColor),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(r.roomId,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badgeLabel,
                  style: TextStyle(
                      color: badgeColor, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('yyyy-MM-dd HH:mm').format(r.startTime)} → ${DateFormat('HH:mm').format(r.endTime)}',
          ),
          const SizedBox(height: 4),
          Text('User: ${r.userId}'),
          Text('Mục đích: ${r.purpose}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: null,
                child: Text(badgeLabel),
              ),
              if (!isRejected) ...[
                ElevatedButton(
                  onPressed: () => _showInvoiceDialog(r),
                  child: const Text('Hóa đơn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ]),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trạng thái đã chuyển → ${newStatus.toUpperCase()}'),
          backgroundColor: _badgeColor(newStatus),
        ),
      );
    } else {
      throw Exception('Không thể cập nhật: ${res.body}');
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
    final pending = _pending
        .where((r) =>
    r.roomId.toLowerCase().contains(filter) ||
        r.userId.toLowerCase().contains(filter))
        .toList();
    final ongoing = _ongoing
        .where((r) =>
    r.roomId.toLowerCase().contains(filter) ||
        r.userId.toLowerCase().contains(filter))
        .toList();
    final historyList = _filteredPast
        .where((r) =>
    r.roomId.toLowerCase().contains(filter) ||
        r.userId.toLowerCase().contains(filter))
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Quản lý đặt phòng', style: TextStyle(color: AppColors.white)),
          bottom: const TabBar(
            indicatorColor: AppColors.white,
            tabs: [
              Tab(text: 'Yêu cầu'),
              Tab(text: 'Đang mượn'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: 'Tìm phòng hoặc user...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Pending
                  pending.isEmpty
                      ? const Center(child: Text('Không có yêu cầu.'))
                      : ListView(children: pending.map(_buildRequestCard).toList()),

                  // Ongoing
                  ongoing.isEmpty
                      ? const Center(child: Text('Không có booking đang diễn ra.'))
                      : ListView(children: ongoing.map(_buildOngoingCard).toList()),

                  // Lịch sử + hóa đơn
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _historyFilter,
                              decoration: InputDecoration(
                                labelText: 'Xem theo',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              items: ['Tất cả','Ngày','Tháng','Quý','Năm']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _historyFilter = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_historyFilter == 'Ngày')
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _historyDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (d != null) setState(() => _historyDate = d);
                                },
                                child: Text(DateFormat('yyyy-MM-dd').format(_historyDate)),
                              ),
                            )
                          else if (_historyFilter == 'Tháng')
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final y = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime(_historyYear, _historyMonth),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                    selectableDayPredicate: (_) => false,
                                  );
                                  if (y != null) setState(() {
                                    _historyYear = y.year;
                                    _historyMonth = y.month;
                                  });
                                },
                                child: Text('${_historyYear}-${_historyMonth.toString().padLeft(2,'0')}'),
                              ),
                            )
                          else
                            const Spacer(),
                        ]),
                        const SizedBox(height: 16),
                        Expanded(
                          child: historyList.isEmpty
                              ? const Center(child: Text('Không có lịch sử.'))
                              : ListView.builder(
                            itemCount: historyList.length,
                            itemBuilder: (ctx, i) => _buildPastCard(historyList[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
