import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Room.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:bookworm/theme/AppColor.dart';

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
    _loadFakeData();
  }

  void _loadFakeData() {
    rooms = [
      Room(id: 'r01', name: 'Phòng 101', floor: 'Tầng 1', capacity: 10, fee: 50000),
      Room(id: 'r02', name: 'Phòng 202', floor: 'Tầng 2', capacity: 15, fee: 60000),
      Room(id: 'r03', name: 'Phòng 303', floor: 'Tầng 3', capacity: 20, fee: 70000),
    ];

    bookings = [
      RoomBookingRequest(
        id: 'b01',
        userId: widget.userId,
        roomId: 'r01',
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        status: 'pending',
        purpose: 'Thảo luận nhóm',
        requestTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
      RoomBookingRequest(
        id: 'b02',
        userId: widget.userId,
        roomId: 'r02',
        startTime: DateTime.now().add(const Duration(days: 2)),
        endTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
        status: 'approved',
        purpose: 'Học nhóm ôn thi',
        requestTime: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RoomBookingRequest(
        id: 'b03',
        userId: widget.userId,
        roomId: 'r03',
        startTime: DateTime.now().add(const Duration(days: 3)),
        endTime: DateTime.now().add(const Duration(days: 3, hours: 1)),
        status: 'rejected',
        purpose: 'Offline lớp',
        requestTime: DateTime.now().subtract(const Duration(days: 3)),
      ),
      RoomBookingRequest(
        id: 'b04',
        userId: widget.userId,
        roomId: 'r01',
        startTime: DateTime.now().add(const Duration(days: 4)),
        endTime: DateTime.now().add(const Duration(days: 4, hours: 1)),
        status: 'cancelled',
        purpose: 'Đổi ý, bận lịch khác',
        requestTime: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
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
            Text('Trạng thái: ${req.status.toUpperCase()}', style: TextStyle(color: statusColor(req.status))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
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
            trailing: Text(
              req.status.toUpperCase(),
              style: TextStyle(color: statusColor(req.status), fontWeight: FontWeight.bold),
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
