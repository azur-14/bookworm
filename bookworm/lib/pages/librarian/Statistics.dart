import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
/// Trang Thống kê phiếu phạt & doanh thu đặt phòng (dữ liệu giả lập)
class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<Bill> bills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final fetchedBills = await fetchBills();
      setState(() => bills = fetchedBills);
    } catch (e) {
      debugPrint('Lỗi tải bills: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải hóa đơn: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phân loại và tính toán
    final bookPenalties   = bills.where((b) => b.type == 'book').toList();
    final roomInvoices    = bills.where((b) => b.type == 'room').toList();
    final int totalPenalties     = bookPenalties.length;
    final double totalRevenue    = bills.fold(0.0, (sum, b) => sum + b.amountReceived);
    final double penaltyRevenue  = bookPenalties.fold(0.0, (sum, b) => sum + b.amountReceived);
    final double roomRevenue     = roomInvoices.fold(0.0, (sum, b) => sum + b.amountReceived);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Phạt & Doanh thu'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tổng quan ở trên
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Phiếu phạt',
                    count: totalPenalties,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: 'Doanh thu',
                    amount: totalRevenue,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  // Phần phiếu phạt
                  Text(
                    'Phiếu phạt – ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(penaltyRevenue)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...bookPenalties.map((b) => InkWell(
                    onTap: () => _showBillDetailDialog(context, b),
                    child: _BillTile(bill: b),
                  )),
                  const Divider(height: 32),
                  // Phần hóa đơn phòng
                  Text(
                    'Hóa đơn phòng – ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(roomRevenue)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        title: Text('Chi tiết hóa đơn ${b.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loại: ${b.type == 'book' ? 'Phạt sách' : 'Đặt phòng'}'),
            Text('Request ID: ${b.requestId}'),
            if (b.overdueDays != null) Text('Trễ: ${b.overdueDays} ngày'),
            if (b.overdueFee  != null) Text('Phí quá hạn: ${NumberFormat.decimalPattern().format(b.overdueFee)}₫'),
            if (b.damageFee   != null) Text('Phí hư hại: ${NumberFormat.decimalPattern().format(b.damageFee)}₫'),
            Text('Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(b.totalFee)}'),
            Text('Khách đưa: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(b.amountReceived)}'),
            Text('Trả lại: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(b.changeGiven)}'),
            Text('Ngày lập: ${DateFormat('yyyy-MM-dd – HH:mm').format(b.date)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

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
  final String label;
  final int? count;
  final double? amount;
  final Color color;

  const _StatCard({
    Key? key,
    required this.label,
    this.count,
    this.amount,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayText = amount != null
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
              displayText,
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
    final color = bill.type == 'book' ? Colors.red : Colors.green;
    final icon  = bill.type == 'book' ? Icons.book : Icons.meeting_room;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text('ID: ${bill.id}'),
        subtitle: Text(DateFormat('yyyy-MM-dd – HH:mm').format(bill.date)),
        trailing: Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(bill.amountReceived),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
