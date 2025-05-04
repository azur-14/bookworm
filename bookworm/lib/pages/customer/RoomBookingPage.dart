import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/Room.dart';
import '../../model/RoomBookingRequest.dart';
import '../../theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class RoomBookingPage extends StatefulWidget {
  @override
  State<RoomBookingPage> createState() => _RoomBookingPageState();
}

class _RoomBookingPageState extends State<RoomBookingPage> {
  List<Room> _rooms = [];

  final Map<String, List<RoomBookingRequest>> _bookingMap = {};
  final Set<DateTime> _selectedSlots = {};
  Room? _activeRoom;
  int _weekOffset = 0;
  final TextEditingController _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  final now = DateTime.now();
  void _showCustomTimeDialog(Room room) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: 30)),
    );
    if (pickedDate == null) return;

    TimeOfDay? start = await showTimePicker(
        context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
    if (start == null) return;
    TimeOfDay? end = await showTimePicker(context: context,
        initialTime: TimeOfDay(hour: start.hour + 1, minute: 0));
    if (end == null) return;

    final startTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, start.hour,
        start.minute);
    final endTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, end.hour,
        end.minute);

    _saveBooking(room, startTime, endTime);
  }

  // void _goToPaymentScreen(Room room, DateTime start, DateTime end) {
  //   final total = ((end
  //       .difference(start)
  //       .inMinutes / 60).ceil()) * room.fee;
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) =>
  //           PaymentScreen(
  //             amount: total,
  //             onSuccess: () => _saveBooking(room, start, end),
  //           ),
  //     ),
  //   );
  // }

  void _saveBooking(Room room, DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'demoUser';
    final newRequest = RoomBookingRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // chỉ local
      userId: userId,
      roomId: room.id,
      startTime: start,
      endTime: end,
      status: 'pending',
      purpose: _purposeController.text.trim(),
      requestTime: DateTime.now(),
    );

    try {
      setState(() {
        _bookingMap.putIfAbsent(room.id, () => []).add(newRequest);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt phòng thành công!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt phòng thất bại: $e')));
    }
  }

  void _openSchedule(Room room) {
    final bookings = _bookingMap[room.id] ?? [];
    final now = DateTime.now();
    final weekStart = now.add(Duration(days: _weekOffset * 7));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final startHour = 8;
    final endHour = 18;
    _selectedSlots.clear();
    _activeRoom = room;

    showDialog(
      context: context,
      builder: (_) => Dialog(
      insetPadding: EdgeInsets.zero, // bỏ giới hạn padding
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) =>
                  Container(
                    width: 800,
                    height: 520,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Lịch phòng: ${room.name}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _weekOffset > 0
                                  ? () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _weekOffset--;
                                });
                                _openSchedule(room);
                              }
                                  : null, // vô hiệu hóa nếu đang ở tuần hiện tại
                            ),
                            SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _weekOffset++;
                                });
                                _openSchedule(room);
                              },
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showCustomTimeDialog(room),
                              icon: const Icon(Icons.add),
                              label: const Text('Chọn giờ tùy ý'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row header: ngày
                                  Row(
                                    children: [
                                      const SizedBox(width: 80), // chừa khoảng cho giờ
                                      ...days.map((d) => Container(
                                        width: 100,
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.all(2),
                                        child: Text(
                                          DateFormat('E\ndd/MM').format(d),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      )),
                                    ],
                                  ),
                                  // Grid: giờ x ngày
                                  ...List.generate(endHour - startHour, (i) {
                                    final hour = startHour + i;
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: Text('${hour}:00', style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ),
                                        ...days.map((day) {
                                          final slot = DateTime(day.year, day.month, day.day, hour);
                                          final slotEnd = slot.add(const Duration(hours: 1));

                                          // 1. Kiểm tra booking
                                          final isBooked = bookings.any((b) {
                                            final localStart = b.startTime.subtract(const Duration(hours: 7));
                                            final localEnd = b.endTime.subtract(const Duration(hours: 7));
                                            return b.status != 'rejected' && b.status != 'cancelled' &&
                                                localStart.isBefore(slotEnd) &&
                                                localEnd.isAfter(slot);
                                          });

                                          // 2. Kiểm tra đã qua
                                          final isPast = slot.isBefore(now);

                                          // 3. Đã chọn chưa
                                          final isSelected = _selectedSlots.contains(slot);

                                          // 4. Chỉ cho chọn khi không booked và không quá khứ
                                          final canSelect = !isBooked && !isPast;

                                          return GestureDetector(
                                            // chỉ bật tap khi canSelect == true
                                            onTap: canSelect
                                                ? () {
                                              setStateDialog(() {
                                                if (isSelected)
                                                  _selectedSlots.remove(slot);
                                                else
                                                  _selectedSlots.add(slot);
                                              });
                                            }
                                                : null,
                                            child: Container(
                                              margin: const EdgeInsets.all(2),
                                              width: 100,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isBooked
                                                    ? Colors.red[200]       // đã có booking
                                                    : isSelected
                                                    ? Colors.green[200] // đã chọn
                                                    : isPast
                                                    ? Colors.grey[300] // đã qua
                                                    : Colors.grey[100], // trống và trong tương lai
                                                border: Border.all(color: Colors.grey),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Lý do sử dụng phòng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _purposeController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Nhập lý do...',
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(ctx),
                                child: const Text('Đóng')),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _selectedSlots.isEmpty
                                  ? null
                                  : () async {
                                final prefs = await SharedPreferences.getInstance();
                                final userId = prefs.getString('userId') ?? 'demoUser';
                                final room = _activeRoom!;
                                final requestTime = DateTime.now();
                                final purpose = _purposeController.text.trim();
                                try {
                                  await sendBookingRequest(
                                    userId: userId,
                                    roomId: room.id,
                                    purpose: purpose,
                                    requestTime: requestTime,
                                    selectedSlots: _selectedSlots.toList(),
                                  );
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt phòng thành công!')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                }
                              },
                              child: const Text('Đặt các giờ đã chọn'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
              ),
            ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Danh sách phòng',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ListView.builder(
          itemCount: _rooms.length,
          itemBuilder: (context, idx) {
            final r = _rooms[idx];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: AppColors.white,
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openSchedule(r),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.meeting_room_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.floor} · ${r.capacity} chỗ',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(r.fee / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(color: AppColors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<List<Room>> fetchRooms() async {
    final res = await http.get(Uri.parse('http://localhost:3001/api/rooms'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Room>.from(data.map((r) => Room.fromJson(r)));
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  Future<void> _loadData() async {
    try {
      final fetchedRooms = await fetchRooms();
      final fetchedBookings = await fetchAllRoomBookingRequests();

      final bookingMap = <String, List<RoomBookingRequest>>{};
      for (var req in fetchedBookings) {
        bookingMap.putIfAbsent(req.roomId, () => []).add(req);
      }

      setState(() {
        _rooms = fetchedRooms;
        _bookingMap.clear();
        _bookingMap.addAll(bookingMap); // cập nhật vào map
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu phòng hoặc đặt phòng: $e');
    }
  }

  Future<void> sendBookingRequest({
    required String userId,
    required String roomId,
    required String purpose,
    required DateTime requestTime,
    required List<DateTime> selectedSlots,
  }) async {
    selectedSlots.sort();
    final merged = <Map<String, String>>[];
    DateTime start = selectedSlots.first;
    DateTime end = start.add(const Duration(hours: 1));

    for (int i = 1; i < selectedSlots.length; i++) {
      final slot = selectedSlots[i];
      if (slot == end) {
        end = end.add(const Duration(hours: 1));
      } else {
        merged.add({
          'start_time': start.toIso8601String(),
          'end_time': end.toIso8601String(),
        });
        start = slot;
        end = slot.add(const Duration(hours: 1));
      }
    }
    merged.add({
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
    });

    final url = Uri.parse('http://localhost:3002/api/roomBookingRequest');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'room_id': roomId,
        'purpose': purpose,
        'request_time': requestTime.toIso8601String(),
        'slots': merged,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Lỗi khi gửi yêu cầu đặt phòng: ${res.body}');
    }
  }

  Future<List<RoomBookingRequest>> fetchAllRoomBookingRequests() async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/roomBookingRequest'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<RoomBookingRequest>.from(data.map((e) => RoomBookingRequest.fromJson(e)));
    } else {
      throw Exception('Lỗi khi tải RoomBookingRequest');
    }
  }

}