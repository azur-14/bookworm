import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model/Room.dart';
import 'model/RoomBookingRequest.dart';
//viet ham load Room
//viet ham load RoomBookingRequest
//update  _showViewRoomDialog()

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({Key? key}) : super(key: key);

  @override
  _RoomManagementPageState createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;

  // Danh sách phòng mẫu.
  final List<Room> _rooms = [
    Room(id: '1', name: 'A1', floor: '1', capacity: 5, fee: 20000),
    Room(id: '2', name: 'A2', floor: '1', capacity: 2, fee: 20000),
    Room(id: '3', name: 'A3', floor: '1', capacity: 2, fee: 15000),
    Room(id: '4', name: 'B1', floor: '2', capacity: 4, fee: 20000),
    Room(id: '5', name: 'B2', floor: '2', capacity: 3, fee: 10000),
    Room(id: '6', name: 'C1', floor: '3', capacity: 1, fee: 10000),
  ];

  // Danh sách yêu cầu đặt phòng.
  Map<String, List<RoomBookingRequest>> _roomBookingRequests = {
    '1': [
      RoomBookingRequest(
        id: 'rbr1',
        userId: 'user123',
        roomId: '1',
        startTime: DateTime.now().add(Duration(hours: 0)),
        endTime: DateTime.now().add(Duration(hours: 2)),
        status: 'approved',
        purpose: 'Họp nhóm',
        requestTime: DateTime.now().subtract(Duration(minutes: 30)),
      ),
    ],
    '2': [
      RoomBookingRequest(
        id: 'rbr2',
        userId: 'user456',
        roomId: '2',
        startTime: DateTime.now().add(Duration(hours: 2)),
        endTime: DateTime.now().add(Duration(hours: 3)),
        status: 'pending',
        purpose: 'Thảo luận dự án',
        requestTime: DateTime.now().subtract(Duration(minutes: 45)),
      ),
    ],
    // Các phòng khác có thể thêm tương tự...
  };

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Hàm tính trạng thái của phòng dựa trên booking request được phê duyệt và thời gian hiện tại.
  String _getRoomStatus(Room room) {
    List<RoomBookingRequest> requests = _roomBookingRequests[room.id] ?? [];
    DateTime now = DateTime.now();
    bool occupied = requests.any((req) =>
    req.status == 'approved' && now.isAfter(req.startTime) && now.isBefore(req.endTime));
    return occupied ? 'occupied' : 'available';
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700])),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  // Hộp thoại xem chi tiết phòng với danh sách booking request và cập nhật trạng thái.
  Future<void> _showViewRoomDialog(Room room) async {
    List<RoomBookingRequest> requests = _roomBookingRequests[room.id] ?? [];
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.brown),
                const SizedBox(width: 8),
                Text('View Room', style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReadOnlyField('ID', room.id),
                    _buildReadOnlyField('Name', room.name),
                    _buildReadOnlyField('Floor', room.floor),
                    _buildReadOnlyField('Capacity', room.capacity.toString()),
                    _buildReadOnlyField('Fee per hour', room.fee.toString()),
                    _buildReadOnlyField('Status', _getRoomStatus(room)),
                    const SizedBox(height: 20),
                    const Text(
                      'Booking Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    requests.isNotEmpty
                        ? Column(
                      children: requests.map((request) {
                        final durationMinutes = request.endTime.difference(request.startTime).inMinutes;
                        final durationHours = durationMinutes / 60;
                        final totalFee = durationHours * room.fee;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('User ID: ${request.userId}'),
                                    Text('Purpose: ${request.purpose}'),
                                    Text(
                                      'Request Time: ${DateFormat('hh:mm a, MMM dd, yyyy').format(request.requestTime)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      'Start: ${DateFormat('hh:mm a, MMM dd, yyyy').format(request.startTime)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      'End: ${DateFormat('hh:mm a, MMM dd, yyyy').format(request.endTime)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      'Status: ${request.status}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Total Fee: ${totalFee.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                              if (request.status == 'pending')
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () {
                                        setStateDialog(() {
                                          request.status = 'approved';
                                        });
                                        setState(() {}); // cập nhật trạng thái tổng thể nếu cần.
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setStateDialog(() {
                                          request.status = 'rejected';
                                        });
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                        : const Text('No booking requests.'),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('CLOSE'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget buildResponsiveDataTable() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Floor')),
              DataColumn(label: Text('Capacity')),
              DataColumn(label: Text('Fee per hour')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: _rooms.map((Room room) {
              String status = _getRoomStatus(room);
              return DataRow(cells: [
                DataCell(Text(room.id)),
                DataCell(Text(room.name, overflow: TextOverflow.ellipsis)),
                DataCell(Text(room.floor)),
                DataCell(Text(room.capacity.toString())),
                DataCell(Text(room.fee.toString())),
                DataCell(Text(status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () {
                          _showViewRoomDialog(room);
                        },
                      ),
                      // Có thể thêm nút Update/Delete nếu cần.
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = DateFormat('hh:mm a').format(_currentTime);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFFFF3EB),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Management',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by ID or Name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: buildResponsiveDataTable(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
