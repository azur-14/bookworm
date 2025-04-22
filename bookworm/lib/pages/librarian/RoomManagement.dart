import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Room.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({Key? key}) : super(key: key);

  @override
  _RoomManagementPageState createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;

  final TextEditingController _searchController = TextEditingController();
  List<Room> _filteredRooms = [];

  final List<Room> _rooms = [];
  Map<String, List<RoomBookingRequest>> _roomBookingRequests = {};

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    _loadRooms().then((_) {
      fetchAndSetRoomBookingRequests();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
                    const Text('Booking Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                    Text('Request Time: ${DateFormat('hh:mm a, MMM dd, yyyy').format(request.requestTime)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    Text('Start: ${DateFormat('hh:mm a, MMM dd, yyyy').format(request.startTime)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    Text('End: ${DateFormat('hh:mm a, MMM dd, yyyy').format(request.endTime)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    Text('Status: ${request.status}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('Total Fee: ${totalFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
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
                                        setState(() {});
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
            rows: _filteredRooms.map((Room room) {
              String status = _getRoomStatus(room);
              bool hasRequests = _roomBookingRequests[room.id]?.isNotEmpty ?? false;
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
                      Tooltip(
                        message: hasRequests ? 'Có yêu cầu đặt phòng' : 'Không có yêu cầu đặt phòng',
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.visibility,
                                color: hasRequests ? Colors.red : Colors.blue,
                              ),
                              onPressed: () {
                                _showViewRoomDialog(room);
                              },
                            ),
                            if (hasRequests)
                              const Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(Icons.circle, size: 10, color: Colors.orange),
                              ),
                          ],
                        ),
                      ),
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
                const Text('Room Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterRooms,
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

  void _filterRooms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRooms = List.from(_rooms);
      } else {
        _filteredRooms = _rooms.where((room) {
          return room.id.toLowerCase().contains(query.toLowerCase()) ||
              room.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<List<Room>> fetchRooms() async {
    final response = await http.get(Uri.parse('http://localhost:3001/api/rooms'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Room.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách phòng');
    }
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await fetchRooms();
      setState(() {
        _rooms.clear();
        _rooms.addAll(rooms);
        _filteredRooms = List.from(_rooms);
      });
    } catch (e) {
      print('Lỗi khi tải phòng: $e');
    }
  }

  Future<void> fetchAndSetRoomBookingRequests() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3002/api/roomBookingRequest'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Map<String, List<RoomBookingRequest>> result = {};
        for (var item in data) {
          final request = RoomBookingRequest.fromJson(item);
          result.putIfAbsent(request.roomId, () => []).add(request);
        }
        setState(() {
          _roomBookingRequests = result;
        });
      } else {
        throw Exception('Lỗi khi tải danh sách booking requests');
      }
    } catch (e) {
      print('Lỗi khi tải booking requests: $e');
    }
  }
}
