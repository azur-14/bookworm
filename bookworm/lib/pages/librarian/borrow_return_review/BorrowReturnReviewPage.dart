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

import '../../../model/Book.dart';
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
  List<Book> _books = [];
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
    _loadBooks();
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

  Future<void> _loadBooks() async {
    try {
      final resp = await http.get(Uri.parse('http://localhost:3003/api/books'));

      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        setState(() => _books = data.map((e) => Book.fromJson(e)).toList());
      } else {
        throw Exception('Failed to load books: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Lỗi khi tải sách: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải sách: $e')),
      );
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
    if (ret != null && ret.status == 'completed') return 'Đã trả';
    return 'Không rõ';
  }

  Future<List<RequestStatusHistory>> fetchStatusHistory(String requestId) async {
    final res = await http.get(
        Uri.parse('http://localhost:3002/api/requestStatusHistory/$requestId')
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

  Future<void> _postBill(Bill bill) async {
    final url = Uri.parse('http://localhost:3002/api/bill');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': bill.id,
        'borrowRequestId': bill.requestId,
        'type': bill.type,
        'overdueDays': bill.overdueDays,
        'overdueFee': bill.overdueFee,
        'damageFee': bill.damageFee,
        'totalFee': bill.totalFee,
        'amountReceived': bill.amountReceived,
        'changeGiven': bill.changeGiven,
        'date': bill.date.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      print('Gửi bill thành công!');
    } else {
      print('Lỗi gửi bill: ${response.body}');
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
    // 1. NHÁNH CHO 'Đã trả' — dùng ReturnRequest
    if (label == 'Đã trả') {
      final list = _returns
          .where((r) => r.status == 'completed')
          .toList()
        ..sort((a, b) => b.returnDate.compareTo(a.returnDate));

      if (list.isEmpty) {
        return Center(child: Text('Không có "$label".'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final r = list[i];
          final borrow = _borrows.firstWhere((b) => b.id == r.borrowRequestId);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                final borrow = _borrows.firstWhere((b) => b.id == r.borrowRequestId);
                _showBorrowReturnInfo(borrow);
              },
              leading: CircleAvatar(
                backgroundColor: _statusColor(label),
                child: Icon(_statusIcon(label), color: AppColors.white),
              ),
              title: Text('Return ${r.id}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User: ${borrow.userEmail ?? borrow.userId}'),
                  Text('Book: ${borrow.bookTitle}'),
                  Text('Returned: ${DateFormat('yyyy-MM-dd').format(r.returnDate)}'),
                  if (r.condition != null && r.condition!.isNotEmpty)
                    Text('Condition: ${r.condition}'),
                ],
              ),
            ),
          );
        },
      );
    }

    // 2. NHÁNH CHO CÁC TRẠNG THÁI CÒN LẠI — dùng BorrowRequest
    final list = _byStatus(label);
    if (list.isEmpty) {
      return Center(child: Text('Không có "$label".'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final b = list[i];
        // trước khi return, tính toán receiveDate logic:
        final receiveDate = b.receiveDate;
        final now = DateTime.now();
        final hasReceive = receiveDate != null;
        final isToday = hasReceive &&
            now.year == receiveDate!.year &&
            now.month == receiveDate.month &&
            now.day == receiveDate.day;
        final isPast = hasReceive && now.isAfter(receiveDate!);

        final cardColor = (label == 'Chờ nhận' && isPast)
            ? Colors.red.withOpacity(0.1)
            : null;

        Widget trailing = const SizedBox();

        if (label == 'Chờ duyệt') {
          trailing = Wrap(spacing: 8, children: [
            TextButton(onPressed: () => _updateBorrow(b, 'approved'), child: const Text('Approve')),
            TextButton(onPressed: () => _updateBorrow(b, 'rejected'), child: const Text('Reject')),
          ]);
        }
        else if (label == 'Chờ nhận') {
          if (isToday) {
            trailing = Wrap(spacing: 8, children: [
              TextButton(
                onPressed: () async {
                  await _updateBorrow(b, 'received');
                  await _createReturnRequest(b.id!);
                },
                child: const Text('Xác nhận nhận'),
              ),
              TextButton(onPressed: () => _updateBorrow(b, 'cancelled'), child: const Text('Hủy')),
            ]);
          }
          else if (isPast) {
            trailing = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(height: 4),
                const Text('Quá ngày nhận', style: TextStyle(color: Colors.red)),
                TextButton(onPressed: () => _updateBorrow(b, 'cancelled'), child: const Text('Hủy')),
              ],
            );
          }
          else {
            trailing = Wrap(spacing: 8, children: [
              TextButton(onPressed: () => _updateBorrow(b, 'cancelled'), child: const Text('Hủy')),
              TextButton(
                onPressed: () async {
                  await _updateBorrow(b, 'received');
                  await _createReturnRequest(b.id!);
                },
                child: const Text('Đã nhận'),
              ),
            ]);
          }
        }
        else if (label == 'Đang mượn') {
          final ret = _getReturn(b);
          if (ret != null) {
            trailing = Wrap(spacing: 8, children: [
              if (ret.status == 'processing')
                TextButton(onPressed: () => _showCompleteReturnDialog(ret), child: const Text('Hoàn thành')),
              if (ret.status == 'overdue')
                TextButton(onPressed: () => _sendOverdueEmail(ret), child: const Text('Email overdue')),
            ]);
          }
        }

        return Card(
          color: cardColor,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showBorrowReturnInfo(b),

            leading: CircleAvatar(
              backgroundColor: _statusColor(label),
              child: Icon(_statusIcon(label), color: AppColors.white),
            ),
            title: Text(b.bookId),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${b.userEmail ?? b.userId}'),
                Text('Ngày yêu cầu: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}'),
                if (b.receiveDate != null)
                  Text('Ngày nhận: ${DateFormat('yyyy-MM-dd').format(b.receiveDate!)}'),
                Text('Hạn trả: ${DateFormat('yyyy-MM-dd').format(b.dueDate!)}'),
              ],
            ),
            trailing: trailing,
          ),
        );
      },
    );
  }

  void _showBorrowReturnInfo(BorrowRequest b) {
    final ret = _getReturn(b);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết Yêu cầu ${b.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('— Thông tin mượn —', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Borrow ID: ${b.id}'),
              Text('User: ${b.userEmail ?? b.userId}'),
              Text('Book: ${b.bookTitle}'),
              Text('Requested: ${DateFormat('yyyy-MM-dd HH:mm').format(b.requestDate)}'),
              if (b.receiveDate != null)
                Text('Received: ${DateFormat('yyyy-MM-dd HH:mm').format(b.receiveDate!)}'),
              Text('Due: ${DateFormat('yyyy-MM-dd HH:mm').format(b.dueDate!)}'),

              if (ret != null) ...[
                const SizedBox(height: 16),
                const Text('— Thông tin trả —', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Return ID: ${ret.id}'),
                Text('Returned: ${DateFormat('yyyy-MM-dd HH:mm').format(ret.returnDate)}'),
                if (ret.condition != null && ret.condition!.isNotEmpty)
                  Text('Condition: ${ret.condition}'),
                if (ret.returnImageBase64 != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.memory(
                      base64Decode(ret.returnImageBase64!),
                      width: 100,
                      height: 100,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  String _mapConditionToCopyStatus(String condition) {
    switch (condition) {
      case 'Hư hao nhẹ':
        return 'damaged';
      case 'Hư tổn đáng kể':
        return 'damaged';
      case 'Mất':
        return 'lost';
      case 'Nguyên vẹn':
      default:
        return 'available';
    }
  }
  Future<void> _showCompleteReturnDialog(ReturnRequest r) async {
    // 0. Chuẩn bị dữ liệu: tìm borrow & book trước, tránh firstWhere trong builder
    final borrowList = _borrows.where((b) => b.id == r.borrowRequestId).toList();
    if (borrowList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy phiếu mượn.'))
      );
      return;
    }
    final borrow = borrowList.first;

    final bookList = _books.where((bk) => bk.id == borrow.bookId).toList();
    if (bookList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy sách.'))
      );
      return;
    }
    final book = bookList.first;

    // 1. Controllers & state local
    final condCtl = TextEditingController(text: r.condition);
    String? imgBase64 = r.returnImageBase64;
    String amountStr = '';

    // 2. Show dialog
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (_, setSt) {
        // 3. Tính phí
        final int daysLate = DateTime.now()
            .difference(borrow.dueDate!)
            .inDays
            .clamp(0, 999)
            .toInt();
        final int overdueFee = daysLate * overdueFeePerDay;

        double damagePct;
        switch (_selectedState) {
          case 'Hư hao nhẹ':     damagePct = 10;  break;
          case 'Hư tổn đáng kể': damagePct = 50;  break;
          case 'Mất':            damagePct = 100; break;
          default:               damagePct = 0;
        }
        final double damageFee = (damagePct / 100) * book.price;
        final double total     = overdueFee + damageFee;

        return AlertDialog(
          title: Text('Hoàn thành trả ${r.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chọn tình trạng sách
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: const InputDecoration(labelText: 'Tình trạng sách'),
                  items: states.map((s) =>
                      DropdownMenuItem(value: s, child: Text(s))
                  ).toList(),
                  onChanged: (v) => setSt(() => _selectedState = v!),
                ),
                const SizedBox(height: 8),

                // Chọn ảnh
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

                // Hiển thị phí
                Text('Trễ: $daysLate ngày → ${NumberFormat.decimalPattern().format(overdueFee)}₫'),
                Text('Hư hại: $damagePct% của ${NumberFormat.decimalPattern().format(book.price)}₫ '
                    '→ ${NumberFormat.decimalPattern().format(damageFee)}₫'),
                const Divider(),
                Text('Tổng: ${NumberFormat.decimalPattern().format(total)}₫'),
                const SizedBox(height: 8),

                // Nhập tiền khách đưa
                TextField(
                  decoration: const InputDecoration(labelText: 'Khách đưa (₫)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setSt(() => amountStr = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final double paid   = double.tryParse(amountStr) ?? total;
                final double change = (paid - total).clamp(0, paid).toDouble();

                // Tạo bill
                final newBill = Bill(
                  id:                 'bill_${r.borrowRequestId}_${DateTime.now().millisecondsSinceEpoch}',
                  requestId:          r.borrowRequestId,
                  type:               'book',
                  overdueDays:        daysLate,
                  overdueFee:         overdueFee,
                  damageFee:          damageFee,
                  totalFee:           total,
                  amountReceived:     paid,
                  changeGiven:        change,
                );

                // Cập nhật local state
                setState(() {
                  r.status            = 'completed';
                  r.condition         = condCtl.text.trim();
                  r.returnImageBase64 = imgBase64;
                  _bills.add(newBill);
                });

                // Gọi API
                await _updateBorrow(borrow, 'completed');
                await http.put(
                  Uri.parse('http://localhost:3002/api/returnRequest/${r.id}/status'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'newStatus': 'completed',
                    'changedBy': _userId,
                    'condition': condCtl.text.trim(),
                    'returnImageBase64': imgBase64,
                  }),
                );
                await http.put(
                  Uri.parse('http://localhost:3003/api/bookcopies/${borrow.bookCopyId}/status'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'newStatus': _mapConditionToCopyStatus(_selectedState),
                  }),
                );
                await _postBill(newBill);

                Navigator.pop(ctx);

                // Hiện hóa đơn phạt
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
      }),
    );
  }

  void _sendOverdueEmail(ReturnRequest r) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gửi email quá hạn'), backgroundColor: Colors.blue),
    );
  }
  Widget _buildHistoryStats() {
    // Tạo map đếm số BorrowRequest cho mỗi label
    final borrowStats = {
      for (var label in _labels)
        label: _byStatus(label).length,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Thống kê cho mỗi borrow-tab
          for (var label in _labels) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatCard(label: label, count: borrowStats[label]!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // 1. Widget thống kê
    final stats = _buildHistoryStats();

    // 2. Danh sách gom Borrow+Return như trước
    final list = List<BorrowRequest>.from(_borrows)
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));

    return Column(
      children: [
        stats,
        const Divider(height: 1),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Chưa có lịch sử mượn/trả.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final b = list[i];
              final r = _getReturn(b);
              Color cardColor = AppColors.white;
              if (r != null) {
                if (r.status == 'overdue') cardColor = Colors.yellowAccent;
                else if (r.condition?.isNotEmpty ?? false) cardColor = Colors.redAccent;
              }

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _showBorrowReturnInfo(b),
                  leading: Icon(
                    r != null ? Icons.swap_horiz : Icons.login,
                    color: _statusColor(r != null ? 'Đã trả' : 'borrow'),
                  ),
                  title: Text('Request ${b.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Borrowed: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}'),
                      if (b.receiveDate != null)
                        Text('Received: ${DateFormat('yyyy-MM-dd').format(b.receiveDate!)}'),
                      Text('Due: ${DateFormat('yyyy-MM-dd').format(b.dueDate!)}'),
                      if (r != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        Text('Returned: ${DateFormat('yyyy-MM-dd').format(r.returnDate)}'),
                        if (r.condition?.isNotEmpty ?? false)
                          Text('Condition: ${r.condition}'),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

// Card đơn giản cho từng con số
class _StatCard extends StatelessWidget {
  final String label;
  final int count;

  const _StatCard({
    Key? key,
    required this.label,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
