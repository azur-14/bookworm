import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/RoomBookingRequest.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingReviewPage extends StatefulWidget {
  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtl = TextEditingController();
  List<RoomBookingRequest> _allRequests = [];

  // Biến cho Lọc Lịch sử
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

  void _loadRequests() {
    final now = DateTime.now();
    _allRequests = [
      // Mock data
      RoomBookingRequest(
        id: '1',
        userId: 'userA',
        roomId: 'Phòng A',
        startTime: now.subtract(Duration(hours: 1)),
        endTime: now.add(Duration(hours: 1)),
        purpose: 'Họp nhóm',
        status: 'approved',
        requestTime: now.subtract(Duration(days: 1)),
      ),
      RoomBookingRequest(
        id: '2',
        userId: 'userB',
        roomId: 'Phòng A',
        startTime: now.add(Duration(minutes: 30)),
        endTime: now.add(Duration(hours: 2)),
        purpose: 'Thảo luận',
        status: 'pending',
        requestTime: now,
      ),
      RoomBookingRequest(
        id: '3',
        userId: 'userC',
        roomId: 'Phòng B',
        startTime: now.subtract(Duration(days: 2)),
        endTime: now.subtract(Duration(days: 2)).add(Duration(hours: 2)),
        purpose: 'Nghiên cứu',
        status: 'approved',
        requestTime: now.subtract(Duration(days: 3)),
      ),
    ];
  }

  List<RoomBookingRequest> get _pending =>
      _allRequests.where((r) => r.status == 'pending').toList();

  List<RoomBookingRequest> get _ongoing {
    final now = DateTime.now();
    return _allRequests.where((r) =>
    r.status == 'approved' &&
        r.startTime.isBefore(now) &&
        r.endTime.isAfter(now)).toList();
  }

  // 1. Mở rộng _past để bao gồm cả approved (kết thúc) và tất cả các rejected
  List<RoomBookingRequest> get _past {
    final now = DateTime.now();
    return _allRequests.where((r) =>
    // đã approve và kết thúc trước giờ hiện tại
    (r.status == 'approved' && r.endTime.isBefore(now))
        // hoặc đã bị reject (bất kỳ lúc nào)
        || r.status == 'rejected'
    ).toList();
  }


  List<RoomBookingRequest> get _filteredPast {
    switch (_historyFilter) {
      case 'Ngày':
        return _past.where((r) =>
        r.startTime.year == _historyDate.year &&
            r.startTime.month == _historyDate.month &&
            r.startTime.day == _historyDate.day
        ).toList();
      case 'Tháng':
        return _past.where((r) =>
        r.startTime.year == _historyYear &&
            r.startTime.month == _historyMonth
        ).toList();
      case 'Quý':
        return _past.where((r) {
          final q = ((r.startTime.month - 1) ~/ 3) + 1;
          return r.startTime.year == _historyYear && q == _historyQuarter;
        }).toList();
      case 'Năm':
        return _past.where((r) =>
        r.startTime.year == _historyYear
        ).toList();
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
        a.endTime.isAfter(req.startTime)
    );
  }

  Color _badgeColor(String st) {
    switch (st) {
      case 'approved': return Colors.green;
      case 'pending':  return AppColors.primary;
      default:         return Colors.grey;
    }
  }

  Future<void> _updateStatus(RoomBookingRequest r, String newStatus) async {
    // TODO: gọi API cập nhật ở đây
    setState(() => r.status = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Request ${r.id} → ${newStatus.toUpperCase()}'),
      backgroundColor: _badgeColor(newStatus),
    ));
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
            '${DateFormat('yyyy-MM-dd HH:mm').format(r.startTime)} → '
                '${DateFormat('HH:mm').format(r.endTime)}',
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
            '${DateFormat('yyyy-MM-dd HH:mm').format(r.startTime)} → '
                '${DateFormat('HH:mm').format(r.endTime)}',
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

  // 2. Cập nhật buildPastCard để hiển thị badge “REJECTED” màu đỏ
  Widget _buildPastCard(RoomBookingRequest r) {
    final isRejected = r.status == 'rejected';
    final badgeLabel = isRejected ? 'REJECTED' : 'PAST';
    final badgeColor = isRejected ? Colors.red : Colors.grey;

    return Card(
      // nền đỏ nhạt nếu reject, ngược lại trắng
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
            '${DateFormat('yyyy-MM-dd HH:mm').format(r.startTime)} → '
                '${DateFormat('HH:mm').format(r.endTime)}',
          ),
          const SizedBox(height: 4),
          Text('User: ${r.userId}'),
          Text('Mục đích: ${r.purpose}'),
        ]),
      ),
    );
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
    // Chỉ lọc trên dữ liệu lịch sử
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
          title: const Text('Quản lý đặt phòng',
              style: TextStyle(color: AppColors.white)),
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.white,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white,
            tabs: const [
              Tab(text: 'Yêu cầu'),
              Tab(text: 'Đang mượn'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: Column(children: [
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
            child: TabBarView(children: [
              // Pending
              pending.isEmpty
                  ? const Center(child: Text('Không có yêu cầu.'))
                  : ListView(children: pending.map(_buildRequestCard).toList()),
              // Ongoing
              ongoing.isEmpty
                  ? const Center(child: Text('Không có booking đang diễn ra.'))
                  : ListView(children: ongoing.map(_buildOngoingCard).toList()),
              // Lịch sử (có filter theo Ngày/Tháng/Quý/Năm)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    // Dropdown “Xem theo”
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
                    // Nút chọn thời điểm tương ứng
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
                    else if (_historyFilter == 'Quý')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final q = await showModalBottomSheet<int>(
                                context: context,
                                builder: (_) => ListView(
                                  children: List.generate(4, (i) async {
                                    final q = await showModalBottomSheet<int>(
                                      context: context,
                                      builder: (BuildContext ctx) {
                                        return ListView(
                                          children: List.generate(4, (i) {
                                            final label = 'Quý ${i + 1}';
                                            return ListTile(
                                              title: Text(label),
                                              onTap: () => Navigator.pop(ctx, i + 1),
                                            );
                                          }),
                                        );
                                      },
                                    );
                                    if (q != null) {
                                      setState(() => _historyQuarter = q);
                                    }
                                  } as Widget Function(int index)),
                                ),
                              );
                              if (q != null) setState(() => _historyQuarter = q);
                            },
                            child: Text('Q$_historyQuarter/${_historyYear}'),
                          ),
                        )
                      else if (_historyFilter == 'Năm')
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final y = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(_historyYear),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                  selectableDayPredicate: (_) => false,
                                );
                                if (y != null) setState(() => _historyYear = y.year);
                              },
                              child: Text('$_historyYear'),
                            ),
                          )
                        else
                          const Spacer(),
                  ]),
                  const SizedBox(height: 16),
                  Text('Tổng booking: ${historyList.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: historyList.isEmpty
                        ? const Center(child: Text('Không có lịch sử.'))
                        : ListView.builder(
                      itemCount: historyList.length,
                      itemBuilder: (ctx, i) => _buildPastCard(historyList[i]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
