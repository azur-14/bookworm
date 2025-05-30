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
  // ✨ Thêm vào để search & sort
  final TextEditingController _searchCtl = TextEditingController();
  String _searchText = '';
  final List<String> _sortOptions = [
    'Ngày mới nhất', 'Ngày cũ nhất', 'Phòng A-Z', 'Phòng Z-A'
  ];
  String _sortOption = 'Ngày mới nhất';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtl.addListener(() {
      setState(() => _searchText = _searchCtl.text.toLowerCase());
    });

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
    final feeFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Hóa đơn',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.receipt, 'Mã hoá đơn', bill.id),
              _detailRow(Icons.request_page, 'Yêu cầu', bill.requestId),
              _detailRow(
                Icons.calendar_today,
                'Ngày lập',
                DateFormat('yyyy-MM-dd – kk:mm').format(bill.date),
              ),
              const Divider(),
              _detailRow(
                Icons.timer_off,
                'Quá hạn',
                '${bill.overdueDays} ngày → ${feeFormat.format(bill.overdueFee)}',
              ),
              _detailRow(
                Icons.build,
                'Phí hư hỏng',
                feeFormat.format(bill.damageFee),
              ),
              const Divider(),
              _detailRow(
                Icons.payment,
                'Tổng',
                feeFormat.format(bill.totalFee),
                valueStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _detailRow(
                Icons.account_balance_wallet,
                'Khách trả',
                feeFormat.format(bill.amountReceived),
              ),
              _detailRow(
                Icons.change_circle,
                'Tiền thối',
                feeFormat.format(bill.changeGiven),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingList(String status) {
    // 1) lọc status
    var list = bookings.where((b) => b.status == status).toList();

    // 2) lọc search theo tên phòng
    list = list.where((r) {
      final room = getRoom(r.roomId);
      return room != null &&
          room.name.toLowerCase().contains(_searchText);
    }).toList();

    // 3) sort theo _sortOption
    list.sort((a, b) {
      switch (_sortOption) {
        case 'Ngày mới nhất':
          return b.startTime.compareTo(a.startTime);
        case 'Ngày cũ nhất':
          return a.startTime.compareTo(b.startTime);
        case 'Phòng A-Z':
          return getRoom(a.roomId)!.name
              .compareTo(getRoom(b.roomId)!.name);
        case 'Phòng Z-A':
          return getRoom(b.roomId)!.name
              .compareTo(getRoom(a.roomId)!.name);
        default:
          return b.startTime.compareTo(a.startTime);
      }
    });
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
    final feeText = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0
    ).format(room.fee);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // bo nhẹ
        ),
        backgroundColor: AppColors.cardBackground,
        title: Text(
          room.name,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.layers,       'Tầng',       room.floor.toString()),
              _detailRow(Icons.group,        'Sức chứa',   '${room.capacity} người'),
              _detailRow(Icons.attach_money, 'Phí/giờ',    feeText),
              const Divider(),
              _detailRow(Icons.access_time,  'Thời gian',  '${formatDateTime(req.startTime)} → ${formatDateTime(req.endTime)}'),
              const Divider(),
              _detailRow(
                  isCancelled ? Icons.cancel : Icons.info,
                  isCancelled ? 'Lý do hủy' : 'Mục đích',
                  req.purpose
              ),
              const Divider(),
              _detailRow(
                Icons.info_outline,
                'Trạng thái',
                req.status.toUpperCase(),
                valueStyle: TextStyle(
                  color: statusColor(req.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          )
        ],
      ),
    );
  }

// Helper widget để tránh lặp code
  Widget _detailRow(
      IconData icon,
      String label,
      String value, {
        TextStyle? valueStyle,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: valueStyle ?? const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background, // chữ và icon become beige
          title: const Text('Room Booking History'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.background,      // tab text selected = beige
            unselectedLabelColor: AppColors.inactive, // tab text unselected = white70
            indicatorColor: AppColors.background,  // underline = beige
            tabs: const [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Sẵn sàng'),
              Tab(text: 'Từ chối'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ← 【THÊM ĐOẠN NÀY】 Search & Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchCtl,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên phòng...',
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _sortOption,
                      items: _sortOptions.map((opt) =>
                          DropdownMenuItem(value: opt, child: Text(opt))
                      ).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sortOption = v);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0
                        ),
                      ),
                      iconEnabledColor: AppColors.primary,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            // ===== phần cũ =====
            Expanded(
              child: TabBarView(
                children: [
                  buildBookingList('pending'),
                  buildBookingList('approved'),
                  buildBookingList('ready'),
                  buildBookingList('rejected'),
                  buildBookingList('cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
