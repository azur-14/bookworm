import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Room.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/AppColor.dart';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({Key? key}) : super(key: key);

  @override
  _RoomManagementPageState createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;
  String _adminId = '';
  RangeValues _yearRange = const RangeValues(2000, 2025);
  String _statusFilter = 'All';
  String _sortField = 'Name';
  bool _sortAsc = true;
  RangeValues _capacityRange = const RangeValues(0, 100);
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  final List<String> _statusOptions = ['All', 'Available', 'Occupied'];
  final List<String> _sortOptions = ['Name', 'Capacity'];

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

    SharedPreferences.getInstance().then((prefs) {
      _adminId = prefs.getString('userId') ?? 'unknown_admin';
    });

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _statusFilter = prefs.getString('room_status_filter') ?? 'All';
        _sortField = prefs.getString('room_sort_field') ?? 'Name';
        _sortAsc = prefs.getBool('room_sort_asc') ?? true;
        _capacityRange = RangeValues(
          (prefs.getInt('room_capacity_min') ?? 0).toDouble(),
          (prefs.getInt('room_capacity_max') ?? 100).toDouble(),
        );
      });
    });

    _loadRooms().then((_) {
      fetchAndSetRoomBookingRequests();
    });
  }
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('room_status_filter', _statusFilter);
    prefs.setString('room_sort_field', _sortField);
    prefs.setBool('room_sort_asc', _sortAsc);
    prefs.setInt('room_capacity_min', _capacityRange.start.toInt());
    prefs.setInt('room_capacity_max', _capacityRange.end.toInt());
  }
  List<Room> get _processedRooms {
    List<Room> filtered = _rooms.where((room) {
      final matchSearch = room.name.toLowerCase().contains(_searchController.text.toLowerCase()) || room.id.contains(_searchController.text);
      final matchStatus = _statusFilter == 'All' || _getRoomStatus(room) == _statusFilter.toLowerCase();
      final matchCapacity = room.capacity >= _capacityRange.start && room.capacity <= _capacityRange.end;
      return matchSearch && matchStatus && matchCapacity;
    }).toList();

    filtered.sort((a, b) {
      final cmp = _sortField == 'Capacity'
          ? a.capacity.compareTo(b.capacity)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _sortAsc ? cmp : -cmp;
    });

    return filtered;
  }

  List<Room> get _paginatedRooms {
    final start = (_currentPage - 1) * _rowsPerPage;
    return _processedRooms.skip(start).take(_rowsPerPage).toList();
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
    req.status == 'approved' &&
        now.isAfter(req.startTime) &&
        now.isBefore(req.endTime));
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
            child: Text(
              '$label:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.brown[700]),
            ),
          ),
          Expanded(
            child:
            Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _showViewRoomDialog(Room room) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.visibility_outlined, color: Colors.brown),
              const SizedBox(width: 8),
              Text('View Room',
                  style: TextStyle(
                      color: Colors.brown[700], fontWeight: FontWeight.bold)),
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
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: Colors.brown[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditRoomDialog(Room room) async {
    final TextEditingController _feeController =
    TextEditingController(text: room.fee.toString());
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: Colors.brown),
              const SizedBox(width: 8),
              Text('Edit Fee',
                  style: TextStyle(color: Colors.brown[700])),
            ],
          ),
          content: TextField(
            controller: _feeController,
            keyboardType:
            TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fee per hour',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown, // màu chữ trắng
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white, // màu chữ trắng
              ),
              onPressed: () async {
                final int? newFee = int.tryParse(_feeController.text);
                if (newFee == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giá không hợp lệ')),
                  );
                  return;
                }

                final url = Uri.parse('http://localhost:3001/api/rooms/${room.id}/fee');
                final response = await http.put(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'fee': newFee}),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    room.fee = newFee;
                  });
                  await _logAction(
                    adminId: _adminId,
                    actionType: 'EDIT',
                    targetType: 'Room',
                    targetId: room.id,
                    description: 'Updated fee to $newFee for room ${room.name}',
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${response.body}')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
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
              bool hasRequests =
                  _roomBookingRequests[room.id]?.isNotEmpty ?? false;
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
                      // nút View
                      IconButton(
                        icon: Icon(
                          Icons.visibility,
                          color: hasRequests ? Colors.red : Colors.blue,
                        ),
                        onPressed: () => _showViewRoomDialog(room),
                      ),
                      // nút Edit giả lập
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        tooltip: 'Edit fee per hour (giả lập)',
                        onPressed: () => _showEditRoomDialog(room),
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
                const Text('Room Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // --- Tìm kiếm & bộ lọc ---
                Row(
                  children: [
                    // 🔍 Tìm kiếm
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {
                          _filteredRooms = _processedRooms;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search by ID or Name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ⏳ Trạng thái phòng
                    _buildDropdown('Status', _statusFilter, _statusOptions, (val) {
                      setState(() {
                        _statusFilter = val!;
                        _currentPage = 1;
                        _savePreferences();
                        _filteredRooms = _processedRooms;
                      });
                    }),
                    const SizedBox(width: 12),

                    // 🧭 Sắp xếp
                    _buildDropdown('Sort by', _sortField, _sortOptions, (val) {
                      setState(() {
                        _sortField = val!;
                        _savePreferences();
                        _filteredRooms = _processedRooms;
                      });
                    }),
                    IconButton(
                      icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                      onPressed: () => setState(() {
                        _sortAsc = !_sortAsc;
                        _savePreferences();
                        _filteredRooms = _processedRooms;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🎛️ Bộ lọc theo sức chứa
                Row(
                  children: [
                    const Text('Sức chứa:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RangeSlider(
                        values: _capacityRange,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        labels: RangeLabels(
                          _capacityRange.start.toInt().toString(),
                          _capacityRange.end.toInt().toString(),
                        ),
                        onChanged: (range) => setState(() {
                          _capacityRange = range;
                          _savePreferences();
                          _filteredRooms = _processedRooms;
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 📋 Bảng dữ liệu (nền trắng)
                Expanded(
                  child: Card(
                    color: Colors.white, // ✅ Nền trắng
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: buildResponsiveDataTable(),
                    ),
                  ),
                ),

                // 🔢 Phân trang
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() {
                          _currentPage--;
                          _filteredRooms = _processedRooms;
                        })
                            : null,
                      ),
                      Text(
                        'Trang $_currentPage / ${(_processedRooms.length / _rowsPerPage).ceil().clamp(1, 999)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage * _rowsPerPage < _processedRooms.length
                            ? () => setState(() {
                          _currentPage++;
                          _filteredRooms = _processedRooms;
                        })
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.brown[700])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: options.map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            )).toList(),
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
    final response =
    await http.get(Uri.parse('http://localhost:3001/api/rooms'));

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
      final response = await http
          .get(Uri.parse('http://localhost:3002/api/roomBookingRequest'));

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
        throw Exception('Lỗi khi tải booking requests');
      }
    } catch (e) {
      print('Lỗi khi tải booking requests: $e');
    }
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
