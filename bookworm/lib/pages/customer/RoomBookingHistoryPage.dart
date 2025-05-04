// lib/pages/RoomBookingHistoryPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Room.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/model/RequestStatusHistory.dart';
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
      final data = json.decode(res.body) as List;
      return data.map((r) => Room.fromJson(r)).toList();
    }
    throw Exception('Failed to load rooms');
  }

  Future<List<RoomBookingRequest>> fetchRoomBookings(String userId) async {
    final res = await http.get(
      Uri.parse('http://localhost:3002/api/roomBookingRequest/user/$userId'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((r) => RoomBookingRequest.fromJson(r)).toList();
    }
    throw Exception('Failed to load booking requests');
  }

  Future<Bill?> fetchBill(String requestId) async {
    final res = await http.get(
      Uri.parse('http://localhost:3002/api/bills/by-request/$requestId'),
    );
    if (res.statusCode == 200) {
      return Bill.fromJson(json.decode(res.body));
    }
    // nếu không có bill, trả về null
    return null;
  }

  Room? getRoom(String id) {
    try {
      return rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  String formatDateTime(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blueGrey;
      case 'ready':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'approved':
      case 'ready':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _updateBookingStatus(
      String requestId, String oldStatus, String newStatus) async {
    final res = await http.put(
      Uri.parse('http://localhost:3002/api/roomBookingRequest/$requestId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': newStatus}),
    );
    if (res.statusCode != 200) {
      throw Exception('Không thể cập nhật trạng thái: ${res.body}');
    }
    final history = RequestStatusHistory(
      requestId: requestId,
      requestType: 'room',
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: widget.userId,
    );
    final histRes = await http.post(
      Uri.parse('http://localhost:3002/api/requestStatusHistory'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(history.toJson()),
    );
    if (histRes.statusCode != 201) {
      throw Exception('Lỗi khi lưu lịch sử thay đổi: ${histRes.body}');
    }
    await _loadData();
  }

  void _showBillPreview(Bill bill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hóa đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã hóa đơn: ${bill.id}'),
            Text('Yêu cầu: ${bill.requestId}'),
            Text(
              'Ngày lập: ${DateFormat('yyyy-MM-dd – kk:mm').format(bill.date)}',
            ),
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
          )
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
        final room = getRoom(req.roomId)!;

        // pending → cho phép Hủy + Xem chi tiết
        if (req.status == 'pending') {
          return _bookingTile(req, room, trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  _updateBookingStatus(req.id, 'pending', 'cancelled');
                },
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => showDetail(req, room),
                child: const Text('Xem'),
              ),
            ],
          ));
        }


        // approved → Hủy + Xem hóa đơn
        if (req.status == 'approved') {
          return _bookingTile(req, room, trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _updateBookingStatus(req.id, 'approved', 'cancelled'),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final bill = await fetchBill(req.id);
                  if (bill != null) _showBillPreview(bill);
                },
                child: const Text('Xem hóa đơn'),
              ),
            ],
          ));
        }

        // ready → chỉ Xem hóa đơn
        if (req.status == 'ready') {
          return _bookingTile(req, room, trailing: TextButton(
            onPressed: () async {
              final bill = await fetchBill(req.id);
              if (bill != null) _showBillPreview(bill);
            },
            child: const Text('Xem hóa đơn'),
          ));
        }


        // rejected / cancelled → chỉ hiển thị status
        return _bookingTile(req, room, trailing: Text(
          req.status.toUpperCase(),
          style: TextStyle(
            color: statusColor(req.status),
            fontWeight: FontWeight.bold,
          ),
        ));
      },
    );
  }

  Widget _bookingTile(RoomBookingRequest req, Room room, {required Widget trailing}) {
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
        subtitle:
        Text('${formatDateTime(req.startTime)} → ${formatDateTime(req.endTime)}'),
        trailing: trailing,
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
                ? Text('Lý do hủy: ${req.purpose}')
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
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
              Tab(text: 'Sẵn sàng'),
              Tab(text: 'Từ chối'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildBookingList('pending'),
            buildBookingList('approved'),
            buildBookingList('ready'),
            buildBookingList('rejected'),
            buildBookingList('cancelled'),
          ],
        ),
      ),
    );
  }
}
