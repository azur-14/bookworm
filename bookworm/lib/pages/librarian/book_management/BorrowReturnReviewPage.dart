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

class BorrowReturnReviewPage extends StatefulWidget {
  const BorrowReturnReviewPage({Key? key}) : super(key: key);

  @override
  _BorrowReturnReviewPageState createState() => _BorrowReturnReviewPageState();
}

class _BorrowReturnReviewPageState extends State<BorrowReturnReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<BorrowRequest> _borrows = [];
  List<ReturnRequest> _returns = [];
  List<Bill> _bills = [];
  String _selectedState = 'Nguyên vẹn';
  final states = ['Nguyên vẹn', 'Hư hao nhẹ', 'Hư tổn đáng kể', 'Mất'];

  String? _borrowFilter;
  String? _returnFilter;
  String? _userId;

  // Phí cố định
  static const int overdueFeePerDay = 10000;    // 10k VND/ngày
  static const int damageFeePerPercent = 5000;  // 5k VND/% hư hại

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadUserPrefs(); // ✅ thêm dòng này
    _loadMocks();
    _searchCtl.addListener(() => setState(() {}));
  }

  void _loadMocks() {
    final now = DateTime.now();
    fetchAllBorrowRequests().then((list) {
      setState(() => _borrows = list);
    });

    fetchAllReturnRequests().then((list) {
      setState(() => _returns = list);
    });
    _bills.clear();
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
        return Colors.orange;
      case 'approved':
      case 'processing':
        return Colors.blueAccent;
      case 'completed':
        return Colors.green;
      case 'overdue':
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId'); // ✅ thêm dòng này
    });
  }

  // ---------------- Borrow actions ----------------
  Future<void> _updateBorrow(BorrowRequest b, String newStatus, {String reason = ''}) async {
    final response = await http.put(
      Uri.parse('http://localhost:3002/api/borrowRequest/${b.id}/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'newStatus': newStatus,
        'changedBy': _userId,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        b.status = newStatus;
        if (newStatus == 'approved') {
          _returns.add(ReturnRequest(
            id: 'r_${b.id}_${DateTime.now().millisecondsSinceEpoch}',
            borrowRequestId: b.id!,
            status: 'processing',
            returnDate: DateTime.now(),
            returnImageBase64: null,
            condition: null,
          ));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã cập nhật trạng thái mượn: $newStatus'),
        backgroundColor: _statusColor(newStatus),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi cập nhật trạng thái'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _showCancelDialog(BorrowRequest b) async {
    final ctl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hủy borrow ${b.id}'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(labelText: 'Lý do hủy'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateBorrow(b, 'cancelled', reason: ctl.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // ---------------- Return & Billing ----------------

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

  // --------------- Filtering ---------------

  int _statusOrder(String st) {
    switch (st) {
      case 'pending': return 0;
      case 'approved': return 1;
      case 'rejected': return 2;
      case 'cancelled': return 3;
      default: return 4;
    }
  }

  int _returnStatusOrder(String st) {
    switch (st) {
      case 'processing': return 0;
      case 'overdue': return 1;
      case 'completed': return 2;
      default: return 3;
    }
  }

  List<BorrowRequest> get _filteredBorrows {
    final q = _searchCtl.text.toLowerCase();
    final filtered = _borrows.where((b) {
      final bySearch = b.userId.toLowerCase().contains(q) || b.bookId.toLowerCase().contains(q);
      final byFilter = _borrowFilter == null || b.status == _borrowFilter;
      return bySearch && byFilter;
    }).toList();

    filtered.sort((a, b) {
      final cmpStatus = _statusOrder(a.status).compareTo(_statusOrder(b.status));
      return cmpStatus != 0
          ? cmpStatus
          : b.requestDate.compareTo(a.requestDate); // mới hơn lên trước
    });

    return filtered;
  }

  List<ReturnRequest> get _filteredReturns {
    final q = _searchCtl.text.toLowerCase();
    final filtered = _returns.where((r) {
      final bySearch = r.borrowRequestId.toLowerCase().contains(q);
      final byFilter = _returnFilter == null || r.status == _returnFilter;
      return bySearch && byFilter;
    }).toList();

    filtered.sort((a, b) {
      final cmpStatus = _returnStatusOrder(a.status).compareTo(_returnStatusOrder(b.status));
      return cmpStatus != 0
          ? cmpStatus
          : b.returnDate.compareTo(a.returnDate); // mới hơn lên trước
    });

    return filtered;
  }

  // --------------- History ---------------

  List<Map<String, dynamic>> get _historyEvents {
    final ev = <Map<String, dynamic>>[];
    for (var b in _borrows) {
      ReturnRequest? ret;
      try {
        ret = _returns.firstWhere((r) => r.borrowRequestId == b.id!);
      } catch (_) {
        ret = null;
      }
      ev.add({'type': ret != null ? 'both' : 'borrow', 'borrow': b, 'return': ret, 'date': b.requestDate});
    }
    for (var r in _returns) {
      if (!_borrows.any((b) => b.id == r.borrowRequestId)) {
        ev.add({'type': 'returnOnly', 'borrow': null, 'return': r, 'date': r.returnDate});
      }
    }
    ev.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return ev;
  }

  // --------------- Detail dialogs ---------------

  void _showBorrowDetail(BorrowRequest b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết Borrow ${b.id}'),
        content: Text(
          'User: ${b.userId}\n'
              'Book: ${b.bookId}\n'
              'Status: ${b.status}\n'
              'Requested: ${DateFormat('yyyy-MM-dd HH:mm').format(b.requestDate)}',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  void _showReturnDetail(ReturnRequest r) {
    Uint8List? img;
    if (r.returnImageBase64 != null) img = base64Decode(r.returnImageBase64!);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết Return ${r.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Borrow ID: ${r.borrowRequestId}'),
            Text('Returned: ${DateFormat('yyyy-MM-dd HH:mm').format(r.returnDate)}'),
            if (r.condition != null) Text('Condition: ${r.condition}'),
            if (img != null) ...[
              const SizedBox(height: 8),
              Image.memory(img, width: 100, height: 100),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  Future<void> _showCombinedDialog(BorrowRequest b, ReturnRequest r) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết ${b.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mượn: ${b.bookId} — ${b.userId}'),
            Text('Ngày mượn: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}'),
            const Divider(),
            Text('Trả: ${DateFormat('yyyy-MM-dd').format(r.returnDate)}'),
            if (r.condition != null) Text('Condition: ${r.condition}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  // --------------- Build UI ---------------

  Widget _buildBorrowTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _borrowFilter,
            decoration: InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [null, 'pending', 'approved', 'rejected', 'cancelled']
                .map((s) => DropdownMenuItem(value: s, child: Text(s ?? 'Tất cả')))
                .toList(),
            onChanged: (v) => setState(() => _borrowFilter = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filteredBorrows.length,
            itemBuilder: (_, i) {
              final b = _filteredBorrows[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.book, color: _statusColor(b.status)),
                  title: Text(b.bookId),
                  subtitle: Text(
                    'User: ${b.userId}\nMượn: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(spacing: 4, children: [
                    TextButton(
                      onPressed: b.status == 'pending' ? () => _updateBorrow(b, 'approved') : null,
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: b.status == 'pending' ? () => _updateBorrow(b, 'rejected') : null,
                      child: const Text('Reject'),
                    ),
                    if (b.status == 'approved')
                      TextButton(
                        onPressed: () => _showCancelDialog(b),
                        child: const Text('Cancel'),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReturnTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _returnFilter,
            decoration: InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [null, 'processing', 'completed', 'overdue']
                .map((s) => DropdownMenuItem(value: s, child: Text(s ?? 'Tất cả')))
                .toList(),
            onChanged: (v) => setState(() => _returnFilter = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filteredReturns.length,
            itemBuilder: (_, i) {
              final r = _filteredReturns[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.swap_horiz, color: _statusColor(r.status)),
                  title: Text('Borrow#${r.borrowRequestId}'),
                  subtitle: Text('Trả: ${DateFormat('yyyy-MM-dd').format(r.returnDate)}'),
                  trailing: Wrap(spacing: 4, children: [
                    if (r.status != 'completed')
                      TextButton(
                        onPressed: () => _showCompleteReturnDialog(r),
                        child: const Text('Complete'),
                      ),
                    if (r.status == 'overdue')
                      TextButton(
                        onPressed: () => _sendOverdueEmail(r),
                        child: const Text('Email overdue'),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final list = _historyEvents;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final e = list[i];
        final b = e['borrow'] as BorrowRequest?;
        final r = e['return'] as ReturnRequest?;
        final dt = e['date'] as DateTime;
        final dateStr = DateFormat('yyyy-MM-dd').format(dt);
        if (e['type'] == 'both') {
          return ListTile(
            leading: const Icon(Icons.sync_alt),
            title: Text('${b!.bookId} — ${b.userId}'),
            subtitle: Text('Mượn: $dateStr  •  Trả: ${DateFormat('yyyy-MM-dd').format(r!.returnDate)}'),
            onTap: () => _showCombinedDialog(b, r),
          );
        } else if (e['type'] == 'borrow') {
          return ListTile(
            leading: const Icon(Icons.login),
            title: Text('Borrow ${b!.id}'),
            subtitle: Text('Mượn: $dateStr'),
            onTap: () => _showBorrowDetail(b),
          );
        } else {
          return ListTile(
            leading: const Icon(Icons.logout),
            title: Text('Return ${r!.id}'),
            subtitle: Text('Trả: $dateStr'),
            onTap: () => _showReturnDetail(r),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Duyệt Mượn/Trả Sách'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Yêu cầu mượn'),
            Tab(text: 'Yêu cầu trả'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                hintText: 'Tìm user hoặc sách...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBorrowTab(),
                _buildReturnTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<BorrowRequest>> fetchAllBorrowRequests() async {
    final url = Uri.parse('http://localhost:3002/api/borrowRequest');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => BorrowRequest.fromJson(item)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách BorrowRequest: ${response.body}');
    }
  }

  Future<List<ReturnRequest>> fetchAllReturnRequests() async {
    final url = Uri.parse('http://localhost:3002/api/returnRequest');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => ReturnRequest.fromJson(item)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách ReturnRequest: ${response.body}');
    }
  }
}
