// lib/pages/BorrowReturnReviewPage.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/BorowRequest.dart';
import 'package:bookworm/model/ReturnRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/RequestStatusHistory.dart';

class BorrowReturnReviewPage extends StatefulWidget {
  const BorrowReturnReviewPage({Key? key}) : super(key: key);
  @override
  _BorrowReturnReviewPageState createState() => _BorrowReturnReviewPageState();
}

class _BorrowReturnReviewPageState extends State<BorrowReturnReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtl = TextEditingController();
  final _picker = ImagePicker();
  String _selectedState = 'Nguyên vẹn';
  final states = ['Nguyên vẹn', 'Hư hao nhẹ', 'Hư tổn đáng kể', 'Mất'];

  List<BorrowRequest> _borrows = [];
  List<ReturnRequest> _returns = [];
  List<Bill> _bills = [];
  String? _userId;

  static const int overdueFeePerDay = 10000;    // 10k/ngày
  static const int damageFeePerPercent = 5000;  // 5k/% hư hại

  // Các label tab status (bỏ 'Trả quá hạn')
  final List<String> _labels = [
    'Chờ duyệt',
    'Chờ nhận',
    'Đang mượn',
    'Hư hao',
    'Đã trả',
    'Từ chối',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _labels.length + 1, vsync: this);
    _loadUserPrefs();
    _loadBorrowRequests();
    _loadReturnRequests();
  }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getString('userId'));
  }

  Future<void> _loadBorrowRequests() async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/borrowRequest'));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() => _borrows = data.map((e) => BorrowRequest.fromJson(e)).toList());
    }
  }

  ReturnRequest? _getReturn(BorrowRequest b) {
    try {
      return _returns.firstWhere((r) => r.borrowRequestId == b.id);
    } catch (_) {
      return null;
    }
  }

  /// Kết hợp status của borrow + return
  /// Note: ret.status 'overdue' giờ cũng thành 'Đang mượn'
  String getCombinedStatus(BorrowRequest r) {
    final ret = _getReturn(r);
    if (r.status == 'pending') return 'Chờ duyệt';
    if (r.status == 'rejected') return 'Từ chối';
    if (r.status == 'approved' && ret == null) return 'Chờ nhận';
    if (r.status=='received' && ret != null && ret.status == 'processing') {
      return 'Đang mượn';
    }
    if (ret != null && ret.status == 'completed') {
      if (ret.condition != null && ret.condition!.isNotEmpty) return 'Hư hao';
      // nếu returned sau dueDate, vẫn xếp vào 'Đã trả'
      return 'Đã trả';
    }
    return 'Không rõ';
  }

  Future<List<RequestStatusHistory>> fetchStatusHistory(String requestId) async {
    final res = await http.get(
        Uri.parse('http://localhost:3002/api/statusHistory/$requestId')
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data
          .map((e) => RequestStatusHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load status history');
  }
  Color _statusColor(String label) {
    switch (label) {
      case 'Chờ duyệt':   return Colors.orange;
      case 'Chờ nhận':    return Colors.blueAccent;
      case 'Đang mượn':   return Colors.blueAccent;
      case 'Hư hao':      return Colors.redAccent;
      case 'Đã trả':      return Colors.green;
      case 'Từ chối':     return Colors.red;
      default:            return Colors.grey;
    }
  }

  IconData _statusIcon(String label) {
    switch (label) {
      case 'Chờ duyệt':   return Icons.hourglass_top;
      case 'Chờ nhận':    return Icons.inventory_2;
      case 'Đang mượn':   return Icons.book;
      case 'Hư hao':      return Icons.report_problem;
      case 'Đã trả':      return Icons.assignment_turned_in;
      case 'Từ chối':     return Icons.cancel;
      default:            return Icons.help;
    }
  }

  Future<void> _updateBorrow(BorrowRequest b, String newStatus) async {
    final res = await http.put(
      Uri.parse('http://localhost:3002/api/borrowRequest/${b.id}/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'newStatus': newStatus, 'changedBy': _userId}),
    );
    if (res.statusCode == 200) setState(() => b.status = newStatus);
  }

  Future<void> _createReturnRequest(String borrowRequestId) async {
    final url = Uri.parse('http://localhost:3002/api/returnRequest');
    final body = {
      'borrowRequestId': borrowRequestId,
      'status': 'processing',
      'returnDate': DateTime.now().toIso8601String(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      setState(() {
        _returns.add(ReturnRequest.fromJson(data));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo yêu cầu trả')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo yêu cầu trả: ${response.body}')),
      );
    }
  }

  Future<void> _loadReturnRequests() async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/returnRequest'));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() => _returns = data.map((e) => ReturnRequest.fromJson(e)).toList());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải returnRequest: ${res.body}')),
      );
    }
  }

  List<BorrowRequest> _byStatus(String label) {
    return _borrows
        .where((b) => getCombinedStatus(b) == label)
        .toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  Widget _buildStatusTab(String label) {
    final list = _byStatus(label);
    if (list.isEmpty) return Center(child: Text('Không có "$label".'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final b = list[i];
        // trước khi return, tính toán receiveDate logic:
        final receiveDate = b.receiveDate;
        final now = DateTime.now();
        final bool hasReceive = receiveDate != null;
        final bool isToday = hasReceive &&
            now.year == receiveDate!.year &&
            now.month == receiveDate.month &&
            now.day == receiveDate.day;
        final bool isPast = hasReceive && now.isAfter(receiveDate!);
// nền đỏ nếu quá ngày nhận và đang ở tab Chờ nhận
        final cardColor = label == 'Chờ nhận' && isPast
            ? Colors.red.withOpacity(0.1)
            : null;

// xác định trailing
        Widget trailing = const SizedBox();

        if (label == 'Chờ duyệt') {
          trailing = Wrap(spacing: 8, children: [
            TextButton(onPressed: () => _updateBorrow(b, 'approved'), child: const Text('Approve')),
            TextButton(onPressed: () => _updateBorrow(b, 'rejected'), child: const Text('Reject')),
          ]);
        } else if (label == 'Chờ nhận') {
          if (isToday) {
            // Nếu đúng ngày nhận thì cho xác nhận hoặc hủy
            trailing = Wrap(spacing: 8, children: [
              TextButton(
                onPressed: () async {
                  await _updateBorrow(b, 'received');
                  await _createReturnRequest(b.id!);
                },
                child: const Text('Xác nhận nhận'),
              ),
              TextButton(
                onPressed: () => _updateBorrow(b, 'cancelled'),
                child: const Text('Hủy'),
              ),
            ]);
          } else if (isPast) {
            // Nếu đã qua ngày nhận thì báo quá hạn + hủy
            trailing = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(height: 4),
                const Text('Quá ngày nhận', style: TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: () => _updateBorrow(b, 'cancelled'),
                  child: const Text('Hủy'),
                ),
              ],
            );
          } else {
            // Trước ngày nhận: show ngày và cho hủy
            trailing = Wrap(spacing: 8, children: [
              TextButton(
                onPressed: () => _updateBorrow(b, 'cancelled'),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  await _updateBorrow(b, 'received');
                  await _createReturnRequest(b.id!);
                },
                child: const Text('Đã nhận'),
              ),
            ]);
          }}  else if (label == 'Đang mượn') {
      final ret = _getReturn(b);
      if (ret != null) {
        // gom các nút lại thành một Row hoặc Wrap
        trailing = Wrap(
          spacing: 8,
          children: [
            // Nút “Hoàn thành” khi đang processing
            if (ret.status == 'processing')
              TextButton(
                onPressed: () => _showCompleteReturnDialog(ret),
                child: const Text('Hoàn thành'),
              ),

            // Nút “Email overdue” khi trạng thái return là overdue
            if (ret.status == 'overdue')
              TextButton(
                onPressed: () => _sendOverdueEmail(ret),
                child: const Text('Email overdue'),
              ),
          ],
        );
      }
    }

// rồi mới return Card/ListTile:
        return Card(
          color: cardColor,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showBorrowDetail(b),
            leading: CircleAvatar(
              backgroundColor: _statusColor(label),
              child: Icon(_statusIcon(label), color: AppColors.white),
            ),
            title: Text(b.bookId),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${b.userId}'),
                Text('Ngày yêu cầu: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}'),
                if (b.receiveDate != null)
                  Text('Ngày nhận:    ${DateFormat('yyyy-MM-dd').format(b.receiveDate!)}'),
                Text('Hạn trả:      ${DateFormat('yyyy-MM-dd').format(b.dueDate!)}'),
              ],
            ),
            trailing: trailing,
          ),
        );
      },
    );
  }

  List<ReturnRequest> get _filteredReturns {
    final q = _searchCtl.text.toLowerCase();
    return _returns
        .where((r) => r.borrowRequestId.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.returnDate.compareTo(a.returnDate));
  }


  Future<void> _showCompleteReturnDialog(ReturnRequest r) async {
    final condCtl = TextEditingController(text: r.condition);
    String? imgBase64 = r.returnImageBase64;
    String amountStr = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSt) {
          // Tính phí
          final borrow = _borrows.firstWhere((b) => b.id == r.borrowRequestId);
          final due = borrow.dueDate ?? borrow.requestDate;
          final daysLate = r.returnDate.difference(due).inDays.clamp(0, 999);
          final overdueFee = daysLate * overdueFeePerDay;
          int damagePct;
          switch (_selectedState) {
            case 'Hư hao nhẹ':     damagePct = 10;  break;
            case 'Hư tổn đáng kể': damagePct = 50;  break;
            case 'Mất':             damagePct = 100; break;
            default:                damagePct = 0;   // Nguyên vẹn
          }
          final damageFee = damagePct * damageFeePerPercent;

          final total = overdueFee + damageFee;

          return AlertDialog(
            title: Text('Hoàn thành trả ${r.id}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(labelText: 'Tình trạng sách'),
                    items: states.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s))
                    ).toList(),
                    onChanged: (v) => setSt(() => _selectedState = v!),
                  ),

                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Chọn ảnh'),
                    onPressed: () async {
                      final img = await _picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setSt(() => imgBase64 = base64Encode(bytes));
                      }
                    },
                  ),
                  if (imgBase64 != null) ...[
                    const SizedBox(height: 8),
                    Image.memory(base64Decode(imgBase64!)),
                  ],
                  const Divider(),
                  Text('Trễ: $daysLate ngày → ${NumberFormat.decimalPattern().format(overdueFee)}₫'),
                  Text('Hư hại: $damagePct% → ${NumberFormat.decimalPattern().format(damageFee)}₫'),
                  const Divider(),
                  Text('Tổng: ${NumberFormat.decimalPattern().format(total)}₫'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Khách đưa (₫)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setSt(() => amountStr = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
              ElevatedButton(
                onPressed: () {
                  final paid = int.tryParse(amountStr) ?? total;
                  final change = (paid - total).clamp(0, paid);
                  setState(() {
                    // cập nhật return
                    r.status = 'completed';
                    r.condition = condCtl.text.trim();
                    r.returnImageBase64 = imgBase64;
                    // tạo hóa đơn
                    _bills.add(Bill(
                      id: 'bill_${r.borrowRequestId}_${DateTime.now().millisecondsSinceEpoch}',
                      borrowRequestId: r.borrowRequestId,
                      overdueDays: daysLate,
                      overdueFee: overdueFee,
                      damageFee: damageFee,
                      totalFee: total,
                      amountReceived: paid,
                      changeGiven: change,
                    ));
                  });
                  Navigator.pop(ctx);
                  // show hoá đơn
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hóa đơn phạt'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Borrow ID: ${r.borrowRequestId}'),
                          Text('Phí quá hạn: ${NumberFormat.decimalPattern().format(overdueFee)}₫'),
                          Text('Phí hư hại: ${NumberFormat.decimalPattern().format(damageFee)}₫'),
                          const Divider(),
                          Text('Tổng: ${NumberFormat.decimalPattern().format(total)}₫'),
                          Text('Khách đưa: ${NumberFormat.decimalPattern().format(paid)}₫'),
                          Text('Trả lại: ${NumberFormat.decimalPattern().format(change)}₫'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Xác nhận'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sendOverdueEmail(ReturnRequest r) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gửi email quá hạn'), backgroundColor: Colors.blue),
    );
  }

  Widget _buildHistoryTab() {
    final events = <Map<String, dynamic>>[];
    for (var b in _borrows) {
      events.add({'type':'borrow','date':b.requestDate,'data':b});
      final r = _getReturn(b);
      if (r!=null) events.add({'type':'return','date':r.returnDate,'data':r});
    }
    events.sort((a,b)=>b['date'].compareTo(a['date']));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        if (e['type']=='borrow') {
          final b = e['data'] as BorrowRequest;
          return ListTile(
            leading: const Icon(Icons.login),
            title: Text('Borrow ${b.id}'),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(e['date'])),
            onTap: ()=>_showBorrowDetail(b),
          );
        } else {
          final r = e['data'] as ReturnRequest;
          // màu vàng nếu overdue, đỏ nếu hư hao
          Color cardColor = AppColors.white;
          if (r.status=='overdue') {
            cardColor = Colors.yellowAccent;
          } else if (r.condition!=null && r.condition!.isNotEmpty) {
            cardColor = Colors.redAccent;
          }
          return Card(
            color: cardColor,
            margin: const EdgeInsets.only(bottom:12),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Return ${r.id}'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(e['date'])),
              onTap: ()=>_showReturnDetail(r),
            ),
          );
        }
      },
    );
  }

  void _showBorrowDetail(BorrowRequest b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết Borrow ${b.id}'),
        content: SizedBox(
          width: double.maxFinite,
          // nạp lịch sử từ server
          child: FutureBuilder<List<RequestStatusHistory>>(
            future: fetchStatusHistory(b.id!),
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final history = snap.data!;
              return ListView(
                shrinkWrap: true,
                children: [
                  // Thông tin cơ bản
                  Text('User: ${b.userId}'),
                  Text('Requested: ${DateFormat('yyyy-MM-dd HH:mm').format(b.requestDate)}'),
                  if (b.receiveDate != null)
                    Text('ReceiveDate: ${DateFormat('yyyy-MM-dd HH:mm').format(b.receiveDate!)}'),
                  Text('DueDate: ${DateFormat('yyyy-MM-dd HH:mm').format(b.dueDate!)}'),
                  const Divider(),
                  const Text('Status change history:', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Hiển thị từng bản ghi history
                  ...history.map((h) => ListTile(
                    dense: true,
                    title: Text('${h.oldStatus} → ${h.newStatus}'),
                    subtitle: Text(
                        '${DateFormat('yyyy-MM-dd HH:mm').format(h.changeTime)}\n'
                            'By: ${h.changedBy}${h.reason.isNotEmpty ? '\nReason: ${h.reason}' : ''}'
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _showReturnDetail(ReturnRequest r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết Return ${r.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<RequestStatusHistory>>(
            future: fetchStatusHistory(r.id!), // lấy lịch sử thao tác
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snap.hasError)
                return Center(child: Text('Error: ${snap.error}'));

              final history = snap.data!;
              Uint8List? img = r.returnImageBase64 != null
                  ? base64Decode(r.returnImageBase64!)
                  : null;

              return ListView(
                shrinkWrap: true,
                children: [
                  // Thông tin cơ bản
                  Text('Borrow ID: ${r.borrowRequestId}'),
                  Text('Returned: ${DateFormat('yyyy-MM-dd HH:mm').format(r.returnDate)}'),
                  if (r.condition != null) Text('Condition: ${r.condition}'),
                  if (img != null) ...[
                    const SizedBox(height: 8),
                    Image.memory(img, width: 100, height: 100),
                  ],
                  const Divider(),
                  const Text('Status History:', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Danh sách lịch sử thay đổi
                  ...history.map((h) => ListTile(
                    dense: true,
                    title: Text('${h.oldStatus} → ${h.newStatus}'),
                    subtitle: Text(
                        '${DateFormat('yyyy-MM-dd HH:mm').format(h.changeTime)}\n'
                            'By: ${h.changedBy}'
                            '${h.reason.isNotEmpty ? '\nReason: ${h.reason}' : ''}'
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Duyệt Mượn/Trả Sách', style: TextStyle(color: AppColors.white)),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.inactive,
          indicatorColor: AppColors.white,
          tabs: [
            ..._labels.map((l)=>Tab(text:l)),
            const Tab(text:'Lịch sử'),
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
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              ..._labels.map(_buildStatusTab),
              _buildHistoryTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

