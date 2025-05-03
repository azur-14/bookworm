// lib/pages/RoomBookingHistoryPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Room.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoomBookingHistoryPage extends StatefulWidget {
  final String userId;
  const RoomBookingHistoryPage({super.key, required this.userId});

  @override
  State<RoomBookingHistoryPage> createState() => _RoomBookingHistoryPageState();
}

class _RoomBookingHistoryPageState extends State<RoomBookingHistoryPage> {
  List<RoomBookingRequest> bookings = [];
  List<Room> rooms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchedRooms = await fetchRooms();
      final fetchedBookings = await fetchRoomBookings(widget.userId);
      setState(() {
        rooms = fetchedRooms;
        bookings = fetchedBookings;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu phòng: $e');
    }
  }

  Future<List<Room>> fetchRooms() async {
    final res = await http.get(Uri.parse('http://localhost:3001/api/rooms'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data as List).map((r) => Room.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  Future<List<RoomBookingRequest>> fetchRoomBookings(String userId) async {
    final res = await http.get(
        Uri.parse('http://localhost:3002/api/roomBookingRequest/user/$userId')
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data as List).map((r) => RoomBookingRequest.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load booking requests');
    }
  }

  Room? getRoom(String id) {
    try {
      return rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }


  String formatDateTime(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Color statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_top;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'cancelled': return Icons.block;
      default: return Icons.info_outline;
    }
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
    } else {
      throw Exception('Lỗi khi tạo hóa đơn: ${res.body}');
    }
  }

  void _showInvoiceDialog(RoomBookingRequest req, Room room) {
    final now = DateTime.now();
    final overdueDays = now.isAfter(req.endTime)
        ? now.difference(req.endTime).inDays
        : 0;
    final overdueFee = overdueDays * 10000; // 10k/ngày
    final damageFee = req.purpose.contains('hư hỏng') ? 50000 : 0;
    final totalFee = overdueFee + damageFee;

    final amountCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hóa đơn - ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yêu cầu ID: ${req.id}'),
            const SizedBox(height: 8),
            Text('Bắt đầu: ${formatDateTime(req.startTime)}'),
            Text('Kết thúc: ${formatDateTime(req.endTime)}'),
            const Divider(),
            Text('Quá hạn: $overdueDays ngày → ${overdueFee}₫'),
            Text('Phí hư hỏng: ${damageFee}₫'),
            const Divider(),
            Text('TỔNG PHÍ: ${totalFee}₫',
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
            Text('Ngày lập: ${DateFormat('yyyy-MM-dd – kk:mm').format(bill.date)}'),
            const Divider(),
            Text('Quá hạn: ${bill.overdueDays} ngày → ${bill.overdueFee}₫'),
            Text('Phí hư hỏng: ${bill.damageFee}₫'),
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

  void showDetail(RoomBookingRequest req, Room room) {
    final isCancelled = req.status == 'cancelled';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(room.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tầng: ${room.floor}'),
            Text('Sức chứa: ${room.capacity} người'),
            Text('Phí/giờ: ${room.fee} VNĐ'),
            const SizedBox(height: 8),
            Text('Thời gian:'),
            Text('• Bắt đầu: ${formatDateTime(req.startTime)}'),
            Text('• Kết thúc: ${formatDateTime(req.endTime)}'),
            const SizedBox(height: 8),
            isCancelled
                ? Text('Lý do huỷ: ${req.purpose}')
                : Text('Mục đích: ${req.purpose}'),
            const SizedBox(height: 8),
            Text('Trạng thái: ${req.status.toUpperCase()}',
                style: TextStyle(color: statusColor(req.status))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
        ],
      ),
    );
  }

  Widget buildBookingList(String status) {
    final list = bookings.where((b) => b.status == status).toList();
    if (list.isEmpty) return const Center(child: Text('Không có dữ liệu.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final req = list[i];
        final room = getRoom(req.roomId);
        if (room == null) return const SizedBox();

        final now = DateTime.now();
        final canInvoice = req.status == 'approved' && req.endTime.isBefore(now);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => showDetail(req, room),
            leading: CircleAvatar(
              backgroundColor: statusColor(req.status),
              child: Icon(statusIcon(req.status), color: Colors.white),
            ),
            title: Text(room.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${formatDateTime(req.startTime)} → ${formatDateTime(req.endTime)}'),
                Text(
                  req.status == 'cancelled'
                      ? 'Lý do huỷ: ${req.purpose}'
                      : 'Mục đích: ${req.purpose}',
                ),
              ],
            ),
            trailing: canInvoice
                ? ElevatedButton(
              onPressed: () => _showInvoiceDialog(req, room),
              child: const Text('Hóa đơn'),
            )
                : Text(
              req.status.toUpperCase(),
              style: TextStyle(
                color: statusColor(req.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đặt phòng'),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Từ chối'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildBookingList('pending'),
            buildBookingList('approved'),
            buildBookingList('rejected'),
            buildBookingList('cancelled'),
          ],
        ),
      ),
    );
  }
}
