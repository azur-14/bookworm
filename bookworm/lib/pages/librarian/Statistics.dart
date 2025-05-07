import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Trang Thống kê phiếu phạt & doanh thu đặt phòng
class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<Bill> bills = [];

  // FILTER STATE
  String _mode = 'Tất cả'; // 'Tất cả', 'Tháng', 'Quý', 'Năm'
  int _selMonth   = DateTime.now().month;
  int _selQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int _selYear    = DateTime.now().year;
  List<int> _years = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final fetched = await fetchBills();
      setState(() {
        bills = fetched;
        // Build danh sách năm có trong dữ liệu để dropdown
        final yearsInData = fetched.map((b) => b.date.year).toSet().toList();
        _years = yearsInData..sort((a, b) => b.compareTo(a));
        if (!_years.contains(_selYear)) _years.insert(0, _selYear);
      });
    } catch (e) {
      debugPrint('Lỗi tải bills: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải hóa đơn: $e')),
      );
    }
  }

  /// Trả về danh sách đã filter
  List<Bill> get _filteredBills {
    return bills.where((b) {
      final d = b.date;
      switch (_mode) {
        case 'Tháng':
          return d.year == _selYear && d.month == _selMonth;
        case 'Quý':
          final q = ((d.month - 1) ~/ 3) + 1;
          return d.year == _selYear && q == _selQuarter;
        case 'Năm':
          return d.year == _selYear;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _filteredBills;
    final bookPenalties = data.where((b) => b.type == 'book').toList();
    final roomInvoices  = data.where((b) => b.type == 'room').toList();

    final totalPenalties  = bookPenalties.length;
    final totalRevenue    = data.fold<double>(0, (s, b) => s + b.amountReceived);
    final penaltyRevenue  = bookPenalties.fold<double>(0, (s, b) => s + b.amountReceived);
    final roomRevenue     = roomInvoices.fold<double>(0, (s, b) => s + b.amountReceived);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê Tổng Đầu Vào'),
        backgroundColor: AppColors.primary,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ----- FILTER UI -----
            Row(
              children: [
                Text('Bộ lọc:', style: TextStyle(color: AppColors.primary)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _mode,
                  dropdownColor: AppColors.white,
                  items: ['Tất cả', 'Tháng', 'Quý', 'Năm']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _mode = v!),
                ),
                const SizedBox(width: 16),

                if (_mode == 'Tháng') ...[
                  DropdownButton<int>(
                    value: _selMonth,
                    dropdownColor: AppColors.white,
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m')))
                        .toList(),
                    onChanged: (v) => setState(() => _selMonth = v!),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selYear,
                    dropdownColor: AppColors.white,
                    items: _years
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _selYear = v!),
                  ),
                ] else if (_mode == 'Quý') ...[
                  DropdownButton<int>(
                    value: _selQuarter,
                    dropdownColor: AppColors.white,
                    items: List.generate(4, (i) => i + 1)
                        .map((q) => DropdownMenuItem(value: q, child: Text('Quý $q')))
                        .toList(),
                    onChanged: (v) => setState(() => _selQuarter = v!),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selYear,
                    dropdownColor: AppColors.white,
                    items: _years
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _selYear = v!),
                  ),
                ] else if (_mode == 'Năm') ...[
                  DropdownButton<int>(
                    value: _selYear,
                    dropdownColor: AppColors.white,
                    items: _years
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _selYear = v!),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),
            // ----- TỔNG QUAN -----
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Phiếu phạt',
                    count: totalPenalties,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: 'Doanh thu',
                    amount: totalRevenue,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ----- DANH SÁCH BILL -----
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Phiếu phạt – ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(penaltyRevenue)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  ...bookPenalties.map((b) => InkWell(
                    onTap: () => _showBillDetailDialog(context, b),
                    child: _BillTile(bill: b),
                  )),
                  const Divider(height: 32, color: AppColors.inactive),
                  Text(
                    'Hóa đơn phòng – ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(roomRevenue)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  ...roomInvoices.map((b) => InkWell(
                    onTap: () => _showBillDetailDialog(context, b),
                    child: _BillTile(bill: b),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog chi tiết hóa đơn
  void _showBillDetailDialog(BuildContext ctx, Bill b) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết hóa đơn ${b.id}', style: TextStyle(color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loại: ${b.type == 'book' ? 'Phạt sách' : 'Đặt phòng'}'),
            Text('Request ID: ${b.requestId}'),
            if (b.overdueDays != null) Text('Trễ: ${b.overdueDays} ngày'),
            if (b.overdueFee != null)
              Text('Phí quá hạn: ${NumberFormat.decimalPattern().format(b.overdueFee)}₫'),
            if (b.damageFee != null)
              Text('Phí hư hại: ${NumberFormat.decimalPattern().format(b.damageFee)}₫'),
            Text('Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(b.totalFee)}'),
            Text('Khách đưa: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(b.amountReceived)}'),
            Text('Trả lại: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(b.changeGiven)}'),
            Text('Ngày lập: ${DateFormat('yyyy-MM-dd – HH:mm').format(b.date)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Gọi API
  Future<List<Bill>> fetchBills() async {
    final url = Uri.parse('http://localhost:3002/api/bill');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Bill.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách hóa đơn: ${response.body}');
    }
  }
}

/// Card hiển thị label + count hoặc amount
class _StatCard extends StatelessWidget {
  final String  label;
  final int?    count;
  final double? amount;
  final Color   color;

  const _StatCard({
    Key? key,
    required this.label,
    this.count,
    this.amount,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final display = amount != null
        ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount)
        : (count?.toString() ?? '0');

    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color)),
            const SizedBox(height: 8),
            Text(
              display,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile hiển thị thông tin ngắn gọn của một Bill
class _BillTile extends StatelessWidget {
  final Bill bill;
  const _BillTile({Key? key, required this.bill}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          bill.type == 'book' ? Icons.book : Icons.meeting_room,
          color: AppColors.primary,
        ),
        title: Text('ID: ${bill.id}'),
        subtitle: Text(DateFormat('yyyy-MM-dd – HH:mm').format(bill.date)),
        trailing: Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(bill.amountReceived),
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }
}
