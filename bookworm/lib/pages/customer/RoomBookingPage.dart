import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/Room.dart';
import '../../model/RoomBookingRequest.dart';
import '../../theme/AppColor.dart';
import 'PaymentScreen.dart';


class RoomBookingPage extends StatefulWidget {
  @override
  State<RoomBookingPage> createState() => _RoomBookingPageState();
}

class _RoomBookingPageState extends State<RoomBookingPage> {
  final List<Room> _rooms = [
    Room(id: 'r1',
        name: 'Phòng Thảo Luận A',
        floor: 'Tầng 1',
        capacity: 6,
        fee: 20000),
    Room(id: 'r2',
        name: 'Phòng Đọc Yên Tĩnh',
        floor: 'Tầng 2',
        capacity: 4,
        fee: 15000),
  ];

  final Map<String, List<RoomBookingRequest>> _bookingMap = {};
  final Set<DateTime> _selectedSlots = {};
  Room? _activeRoom;

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

    _goToPaymentScreen(room, startTime, endTime);
  }

  void _goToPaymentScreen(Room room, DateTime start, DateTime end) {
    final total = ((end
        .difference(start)
        .inMinutes / 60).ceil()) * room.fee;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentScreen(
              amount: total,
              onSuccess: () => _saveBooking(room, start, end),
            ),
      ),
    );
  }

  void _saveBooking(Room room, DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'demoUser';
    final newRequest = RoomBookingRequest(
      id: DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      userId: userId,
      roomId: room.id,
      startTime: start,
      endTime: end,
      status: 'pending',
      purpose: 'Mặc định',
      requestTime: DateTime.now(),
    );
    setState(() {
      _bookingMap.putIfAbsent(room.id, () => []).add(newRequest);
    });
  }

  void _openSchedule(Room room) {
    final bookings = _bookingMap[room.id] ?? [];
    final now = DateTime.now();
    final days = List.generate(5, (i) => now.add(Duration(days: i)));
    final startHour = 8;
    final endHour = 18;
    _selectedSlots.clear();
    _activeRoom = room;

    showDialog(
      context: context,
      builder: (_) =>
          Dialog(
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
                              child: Row(
                                children: days.map((day) {
                                  return Column(
                                    children: List.generate(
                                        endHour - startHour, (i) {
                                      final hour = startHour + i;
                                      final slot = DateTime(
                                          day.year, day.month, day.day, hour);
                                      final slotEnd = slot.add(
                                          Duration(hours: 1));
                                      final isBooked = bookings.any(
                                            (b) =>
                                        b.startTime.isBefore(slotEnd) &&
                                            b.endTime.isAfter(slot),
                                      );
                                      final isSelected = _selectedSlots
                                          .contains(slot);
                                      return GestureDetector(
                                        onTap: isBooked
                                            ? null
                                            : () {
                                          setStateDialog(() {
                                            if (isSelected) {
                                              _selectedSlots.remove(slot);
                                            } else {
                                              _selectedSlots.add(slot);
                                            }
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(2),
                                          width: 120,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isBooked
                                                ? Colors.red[200]
                                                : isSelected
                                                ? Colors.green[200]
                                                : Colors.grey[100],
                                            border: Border.all(
                                                color: Colors.grey),
                                          ),
                                          child: Center(
                                              child: Text('${hour}:00')),
                                        ),
                                      );
                                    }),
                                  );
                                }).toList(),
                              ),
                            ),
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
                                  : () {
                                final sorted = _selectedSlots.toList()
                                  ..sort();
                                final start = sorted.first;
                                final end = sorted.last.add(Duration(hours: 1));
                                Navigator.pop(ctx);
                                _goToPaymentScreen(room, start, end);
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
}