import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/BorowRequest.dart';    // sửa tên file
import 'package:bookworm/model/ReturnRequest.dart';    // lớp mới có returnImageBase64 & condition

class BorrowReturnReviewPage extends StatefulWidget {
  @override
  _BorrowReturnReviewPageState createState() =>
      _BorrowReturnReviewPageState();
}

class _BorrowReturnReviewPageState extends State<BorrowReturnReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<BorrowRequest> _borrows = [];
  List<ReturnRequest> _returns = [];

  String? _borrowFilter;
  String? _returnFilter;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadMocks();
    _searchCtl.addListener(() => setState(() {}));
  }

  void _loadMocks() {
    final now = DateTime.now();
    _borrows = [
      BorrowRequest(
        id: 'b1',
        userId: 'alice',
        bookCopyId: 'b1',                // thêm trường này
        bookId: 'Clean Code',
        dueDate: now.add(const Duration(days: 7)),
      ),
      BorrowRequest(
        id: 'b2',
        userId: 'bob',
        bookCopyId: 'b2',                // thêm trường này
        bookId: 'Flutter in Action',
        status: 'approved',
        receiveDate: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 6)),
        approvedBy: 'lib1',
        approvedDate: now.subtract(const Duration(days: 1)),
      ),
      BorrowRequest(
        id: 'b3',
        userId: 'carol',
        bookCopyId: 'b3',                // thêm trường này
        bookId: 'Design Patterns',
        status: 'cancelled',
        userCancelReason: 'Trùng lịch học',
        cancelledBy: 'user',
        cancelledDate: now.subtract(const Duration(days: 2)),
      ),
    ];

    _returns = [
      ReturnRequest(
        id: 'r_b2',
        borrowRequestId: 'b2',
        returnDate: now,
        status: 'processing',
        returnImageBase64: null,
        condition: null,
      ),
      ReturnRequest(
        id: 'r_old',
        borrowRequestId: 'b_old',
        returnDate: now.subtract(const Duration(days: 10)),
        status: 'overdue',
        returnImageBase64: null,
        condition: null,
      ),
    ];
  }


  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  Color _statusColor(String st) {
    switch (st) {
      case 'pending':
      case 'processing':
        return AppColors.primary;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // ------------------ Borrow logic ------------------

  void _updateBorrow(BorrowRequest b, String newStatus) {
    setState(() {
      b.status = newStatus;
      if (newStatus == 'approved') {
        b.approvedBy = 'lib1';
        b.approvedDate = DateTime.now();
        // Chỉ thêm khi b.id != null
        if (b.id != null && !_returns.any((r) => r.borrowRequestId == b.id)) {
          final brId = b.id!; // unwrap an toàn ở đây
          _returns.add(ReturnRequest(
            id: 'r_${brId}_${DateTime.now().millisecondsSinceEpoch}',
            borrowRequestId: brId,
            returnDate: DateTime.now(),
          ));
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Borrow ${b.id} → ${newStatus.toUpperCase()}'),
      backgroundColor: _statusColor(newStatus),
    ));
  }


  Future<void> _showCancelDialog(BorrowRequest b) async {
    final ctl = TextEditingController(text: b.librarianCancelReason);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hủy borrow ${b.id}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (b.userCancelReason != null)
            Text('Lý do user: ${b.userCancelReason!}',
                style: const TextStyle(color: Colors.red)),
          TextField(
            controller: ctl,
            decoration:
            const InputDecoration(labelText: 'Lý do hủy (librarian)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () {
              final reason = ctl.text.trim();
              if (reason.isEmpty) return;
              setState(() {
                b.status = 'cancelled';
                b.librarianCancelReason = reason;
                b.cancelledBy = 'librarian';
                b.cancelledDate = DateTime.now();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Borrow ${b.id} hủy bởi librarian'),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // ------------------ Return logic ------------------

  void _sendOverdueEmail(ReturnRequest r) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đã gửi email quá hạn cho Borrow#${r.borrowRequestId}'),
      backgroundColor: Colors.blue,
    ));
  }

  Future<void> _showCompleteReturnDialog(ReturnRequest r) async {
    final condCtl = TextEditingController(text: r.condition);
    String? base64str = r.returnImageBase64;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Hoàn thành trả ${r.id}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: condCtl,
              decoration: const InputDecoration(
                  labelText: 'Tình trạng sách (ví dụ: 90% nguyên vẹn)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image == null) return;
                final Uint8List bytes = await image.readAsBytes();
                setStateDialog(() => base64str = base64Encode(bytes));
              },
              icon: const Icon(Icons.image),
              label: const Text('Chọn ảnh chứng cứ'),
            ),
            if (base64str != null) ...[
              const SizedBox(height: 8),
              Image.memory(
                base64Decode(base64str!),
                width: 80,
                height: 80,
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  r.status = 'completed';
                  r.condition = condCtl.text.trim();
                  r.returnImageBase64 = base64str;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Return marked complete'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }


  // ------------- Filtering & history -------------

  List<BorrowRequest> get _filteredBorrows {
    final q = _searchCtl.text.toLowerCase();
    return _borrows.where((b) {
      final okSearch = b.userId.toLowerCase().contains(q) ||
          b.bookId.toLowerCase().contains(q);
      final okFilt = _borrowFilter == null || b.status == _borrowFilter;
      return okSearch && okFilt;
    }).toList();
  }

  List<ReturnRequest> get _filteredReturns {
    final q = _searchCtl.text.toLowerCase();
    return _returns.where((r) {
      final okSearch = r.borrowRequestId.toLowerCase().contains(q);
      final okFilt = _returnFilter == null || r.status == _returnFilter;
      return okSearch && okFilt;
    }).toList();
  }



Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ]),
      ),
    );
  }

  Widget _buildBorrowCard(BorrowRequest b) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _statusColor(b.status)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${b.bookId} — ${b.userId}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: _statusColor(b.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(b.status.toUpperCase(),
                  style: TextStyle(color: _statusColor(b.status), fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Yêu cầu: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}'),
          if (b.receiveDate != null)
            Text('Nhận: ${DateFormat('yyyy-MM-dd').format(b.receiveDate!)}'),
          if (b.dueDate != null)
            Text('Hạn trả: ${DateFormat('yyyy-MM-dd').format(b.dueDate!)}'),
          if (b.approvedBy != null) Text('Approved by: ${b.approvedBy}'),
          if (b.cancelledBy != null) ...[
            Text('Cancelled by: ${b.cancelledBy}'),
            if (b.userCancelReason != null)
              Text('User reason: ${b.userCancelReason!}'),
            if (b.librarianCancelReason != null)
              Text('Lib reason: ${b.librarianCancelReason!}'),
          ],
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(
              onPressed: b.status == 'pending' ? () => _updateBorrow(b, 'approved') : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: b.status == 'pending' ? () => _updateBorrow(b, 'rejected') : null,
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              child: const Text('Reject'),
            ),
            if (b.status == 'approved') ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showCancelDialog(b),
                child: const Text('Cancel'),
              ),
            ]
          ]),
        ]),
      ),
    );
  }

  Widget _buildReturnTab() {
    final proc = _returns.where((r) => r.status == 'processing').length;
    final comp = _returns.where((r) => r.status == 'completed').length;
    final ovrd = _returns.where((r) => r.status == 'overdue').length;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildStatCard('Processing', proc, AppColors.primary),
          _buildStatCard('Completed', comp, Colors.green),
          _buildStatCard('Overdue', ovrd, Colors.red),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: _returnFilter,
          decoration: InputDecoration(
            labelText: 'Trạng thái',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả')),
            ...['processing', 'completed', 'overdue']
                .map((s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (v) => setState(() => _returnFilter = v),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _filteredReturns.isEmpty
            ? const Center(child: Text('Không có yêu cầu trả.'))
            : ListView(children: _filteredReturns.map(_buildReturnCard).toList()),
      ),
    ]);
  }

  Widget _buildReturnCard(ReturnRequest r) {
    Uint8List? imgBytes;
    if (r.returnImageBase64 != null) {
      imgBytes = base64Decode(r.returnImageBase64!);
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _statusColor(r.status)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Borrow#${r.borrowRequestId}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: _statusColor(r.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.status.toUpperCase(),
                  style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Returned: ${DateFormat('yyyy-MM-dd').format(r.returnDate)}'),
          if (imgBytes != null) ...[
            const SizedBox(height: 8),
            Image.memory(imgBytes, width: 80, height: 80),
          ],
          if (r.condition != null) ...[
            const SizedBox(height: 4),
            Text('Condition: ${r.condition!}'),
          ],
          const SizedBox(height: 12),
// Always allow complete, even if overdue
          if (r.status == 'processing' || r.status == 'overdue') ...[
            ElevatedButton.icon(
              onPressed: () => _showCompleteReturnDialog(r),
              icon: const Icon(Icons.check_circle, color: AppColors.white),
              label: const Text('Complete', style: TextStyle(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (r.status == 'overdue') ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _sendOverdueEmail(r),
                icon: const Icon(Icons.email, color: AppColors.white),
                label: const Text('Gửi email quá hạn', style: TextStyle(color: AppColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }
// 1) Thêm vào State của _BorrowReturnReviewPageState:
  String _historyFilter = 'Tất cả';
  DateTime _historyDate = DateTime.now();
  int _historyYear = DateTime.now().year;
  int _historyMonth = DateTime.now().month;
  int _historyQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;

// 2) Thay thế getter _historyEvents (giữ nguyên như trước)
  List<Map<String, dynamic>> get _historyEvents {
    final List<Map<String, dynamic>> events = [];
    // gộp borrow+return
    for (var b in _borrows) {
      final matches = _returns.where((r) => r.borrowRequestId == b.id).toList();
      if (matches.isNotEmpty) {
        events.add({'type':'both','borrow':b,'return':matches.first,'date':b.requestDate});
      } else {
        events.add({'type':'borrow','borrow':b,'date':b.requestDate});
      }
    }
    // các return chỉ có return
    for (var r in _returns) {
      if (!_borrows.any((b) => b.id == r.borrowRequestId)) {
        events.add({'type':'returnOnly','return':r,'date':r.returnDate});
      }
    }
    events.sort((a,b)=> (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return events;
  }

// 3) Hàm lọc history theo _historyFilter:
  List<Map<String, dynamic>> get _filteredHistory {
    return _historyEvents.where((e) {
      final dt = e['date'] as DateTime;
      switch (_historyFilter) {
        case 'Ngày':
          return dt.year == _historyDate.year &&
              dt.month == _historyDate.month &&
              dt.day == _historyDate.day;
        case 'Tháng':
          return dt.year == _historyYear &&
              dt.month == _historyMonth;
        case 'Quý':
          final q = ((dt.month - 1) ~/ 3) + 1;
          return dt.year == _historyYear && q == _historyQuarter;
        case 'Năm':
          return dt.year == _historyYear;
        default: // 'Tất cả'
          return true;
      }
    }).toList();
  }

// 4) Thay thế hoàn toàn Widget _buildHistoryTab():
  Widget _buildHistoryTab() {
    final list = _filteredHistory;
    // thống kê nhanh
    final total = list.length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Row lọc
          Row(children: [
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
                onChanged: (v) { if (v != null) setState(() => _historyFilter = v); },
              ),
            ),
            const SizedBox(width: 12),
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
                    final pick = await showDatePicker(
                      context: context,
                      initialDate: DateTime(_historyYear, _historyMonth),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      selectableDayPredicate: (_) => false,
                    );
                    if (pick != null) setState(() {
                      _historyYear = pick.year;
                      _historyMonth = pick.month;
                    });
                  },
                  child: Text('$_historyYear-${_historyMonth.toString().padLeft(2,'0')}'),
                ),
              )
            else if (_historyFilter == 'Quý')
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final q = await showModalBottomSheet<int>(
                        context: context,
                        builder: (BuildContext ctx) {
                          return ListView(
                            children: List.generate(4, (i) {
                              final label = 'Quý ${i+1}';
                              return ListTile(
                                title: Text(label),
                                onTap: () => Navigator.pop(ctx, i+1),
                              );
                            }),
                          );
                        },
                      );
                      if (q != null) setState(() => _historyQuarter = q);
                    },
                    child: Text('Q$_historyQuarter/$_historyYear'),
                  ),
                )
              else if (_historyFilter == 'Năm')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: DateTime(_historyYear),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          selectableDayPredicate: (_) => false,
                        );
                        if (pick != null) setState(() => _historyYear = pick.year);
                      },
                      child: Text('$_historyYear'),
                    ),
                  )
                else
                  const Spacer(),
          ]),
          const SizedBox(height: 16),
          // B. Thống kê
          Text('Tổng sự kiện: $total', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // C. Danh sách
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Không có lịch sử.'))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final e = list[i];
                final dt = e['date'] as DateTime;
                final dstr = DateFormat('yyyy-MM-dd').format(dt);
                switch (e['type'] as String) {
                  case 'both':
                    final b = e['borrow'] as BorrowRequest;
                    final r = e['return'] as ReturnRequest;
                    return ListTile(
                      leading: const Icon(Icons.sync_alt, color: Colors.blueAccent),
                      title: Text('${b.bookId} — ${b.userId}'),
                      subtitle: Text('Mượn: $dstr  •  Trả: ${DateFormat('yyyy-MM-dd').format(r.returnDate)}'),
                    );
                  case 'borrow':
                    final b = e['borrow'] as BorrowRequest;
                    return ListTile(
                      leading: const Icon(Icons.login, color: Colors.brown),
                      title: Text('Borrow ${b.id} — ${b.bookId}'),
                      subtitle: Text('Ngày mượn: $dstr'),
                      onTap: () => _showBorrowDetail(b),
                    );
                  case 'returnOnly':
                    final r = e['return'] as ReturnRequest;
                    return ListTile(
                      leading: const Icon(Icons.logout, color: Colors.green),
                      title: Text('Return ${r.id}'),
                      subtitle: Text('Ngày trả: $dstr'),
                      onTap: () => _showReturnDetail(r),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBorrowDetail(BorrowRequest b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chi tiết Borrow ${b.id}'),
        content: Text(
          'User: ${b.userId}\n'
              'Book: ${b.bookId}\n'
              'Status: ${b.status}\n'
              'Requested: ${DateFormat('yyyy-MM-dd HH:mm').format(b.requestDate)}'
              '${b.approvedBy != null ? '\nApproved by: ${b.approvedBy}' : ''}'
              '${b.cancelledBy != null ? '\nCancelled by: ${b.cancelledBy}' : ''}'
              '${b.userCancelReason != null ? '\nUser reason: ${b.userCancelReason}' : ''}'
              '${b.librarianCancelReason != null ? '\nLib reason: ${b.librarianCancelReason}' : ''}',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

  void _showReturnDetail(ReturnRequest r) {
    Uint8List? imgBytes;
    if (r.returnImageBase64 != null) {
      imgBytes = base64Decode(r.returnImageBase64!);
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chi tiết Return ${r.id}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Borrow ID: ${r.borrowRequestId}'),
          Text('Status: ${r.status}'),
          Text('Returned: ${DateFormat('yyyy-MM-dd HH:mm').format(r.returnDate)}'),
          if (r.condition != null) ...[
            const SizedBox(height: 8),
            Text('Condition: ${r.condition!}'),
          ],
          if (imgBytes != null) ...[
            const SizedBox(height: 8),
            Image.memory(imgBytes, width: 100, height: 100),
          ],
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borrows = _filteredBorrows;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Duyệt Mượn/Trả Sách', style: TextStyle(color: AppColors.white)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.white, labelColor: AppColors.white, unselectedLabelColor: AppColors.white,
          tabs: const [
            Tab(text: 'Yêu cầu mượn'),
            Tab(text: 'Yêu cầu trả'),
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
              hintText: 'Tìm user hoặc sách...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            // Borrow tab
            Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _borrowFilter,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ...['pending', 'approved', 'rejected', 'cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setState(() => _borrowFilter = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: borrows.isEmpty
                    ? const Center(child: Text('Không có yêu cầu.'))
                    : ListView(children: borrows.map(_buildBorrowCard).toList()),
              ),
            ]),
            // Return tab
            _buildReturnTab(),
            // History tab
            _buildHistoryTab(),
          ]),
        ),
      ]),
    );
  }
}
