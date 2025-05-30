import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/Bill.dart';

/// Trang Thống kê phiếu phạt & doanh thu đặt phòng
class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  // Dữ liệu bills
  List<Bill> bills = [];

  // Filter state
  String _mode = 'Tháng'; // 'Tất cả', 'Tháng', 'Quý', 'Năm'
  int _selMonth = DateTime
      .now()
      .month;
  int _selQuarter = ((DateTime
      .now()
      .month - 1) ~/ 3) + 1;
  int _selYear = DateTime
      .now()
      .year;
  List<int> _years = [];

  // Tab controller
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    try {
      final fetched = await fetchBills();
      setState(() {
        bills = fetched;
        final yearsInData = fetched
            .map((b) => b.date.year)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
        _years = yearsInData;
        if (!_years.contains(_selYear)) _years.insert(0, _selYear);
      });
    } catch (e) {
      debugPrint('Lỗi tải bills: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải hóa đơn: $e')),
      );
    }
  }

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

  // API fetch
  Future<List<Bill>> fetchBills() async {
    final url = Uri.parse('http://localhost:3002/api/bill');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Bill.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải hóa đơn: ${response.body}');
    }
  }

  void _showBillDetailDialog(BuildContext ctx, Bill b) {
    showDialog(
      context: ctx,
      builder: (_) =>
          AlertDialog(
            title:
            Text('Chi tiết hóa đơn ${b.id}',
                style: TextStyle(color: AppColors.primary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loại: ${b.type == 'book' ? 'Phạt sách' : 'Đặt phòng'}'),
                Text('Request ID: ${b.requestId}'),
                if (b.overdueDays != null) Text('Trễ: ${b.overdueDays} ngày'),
                if (b.overdueFee != null)
                  Text('Phí quá hạn: ${NumberFormat.decimalPattern().format(
                      b.overdueFee)}₫'),
                if (b.damageFee != null)
                  Text('Phí hư hại: ${NumberFormat.decimalPattern().format(
                      b.damageFee)}₫'),
                Text(
                    'Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                        .format(b.totalFee)}'),
                Text(
                    'Khách đưa: ${NumberFormat.currency(
                        locale: 'vi_VN', symbol: '₫').format(
                        b.amountReceived)}'),
                Text(
                    'Trả lại: ${NumberFormat.currency(
                        locale: 'vi_VN', symbol: '₫').format(b.changeGiven)}'),
                Text('Ngày lập: ${DateFormat('yyyy-MM-dd – HH:mm').format(
                    b.date)}'),
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

  @override
  Widget build(BuildContext context) {
    final data = _filteredBills;
    final bookPenalties = data.where((b) => b.type == 'book').toList();
    final roomInvoices = data.where((b) => b.type == 'room').toList();

    // Chuẩn bị dữ liệu cho chart
    Map<String, double> chartData = {};
    if (_mode == 'Tháng') {
      chartData = Map.fromIterables(
        List.generate(12, (i) => 'Tháng ${i + 1}'),
        List.generate(12, (i) =>
            data
                .where((b) => b.date.year == _selYear && b.date.month == i + 1)
                .fold<double>(0, (s, b) => s + b.amountReceived)),
      );
    } else if (_mode == 'Quý') {
      chartData = Map.fromIterables(
        List.generate(4, (i) => 'Q${i + 1}'),
        List.generate(4, (i) =>
            data
                .where((b) =>
            ((b.date.month - 1) ~/ 3) + 1 == i + 1 && b.date.year == _selYear)
                .fold<double>(0, (s, b) => s + b.amountReceived)),
      );
    } else if (_mode == 'Năm') {
      chartData = {
        '$_selYear': data.fold<double>(0, (s, b) => s + b.amountReceived)
      };
    } else {
      final years = data.map((b) => b.date.year).toSet().toList()
        ..sort();
      chartData = {
        for (var y in years)
          '$y': data.where((b) => b.date.year == y)
              .fold<double>(0, (s, b) => s + b.amountReceived)
      };
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê Tổng Đầu Vào'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Biểu đồ'),
            Tab(icon: Icon(Icons.list), text: 'Danh sách'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Bộ lọc:', style: TextStyle(color: AppColors.primary)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _mode, // ensure _mode = 'Tháng' chính thức
                      dropdownColor: AppColors.white,
                      items: ['Tất cả', 'Tháng', 'Quý', 'Năm']
                          .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                    const SizedBox(width: 12),
                    if (_mode == 'Tháng') ...[
                      DropdownButton<int>(
                        value: _selMonth,
                        dropdownColor: AppColors.white,
                        items: List.generate(12, (i) => i + 1)
                            .map((m) =>
                            DropdownMenuItem(value: m, child: Text('Tháng $m')))
                            .toList(),
                        onChanged: (v) => setState(() => _selMonth = v!),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _selYear,
                        dropdownColor: AppColors.white,
                        items: _years.map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (v) => setState(() => _selYear = v!),
                      ),
                    ] else
                      if (_mode == 'Quý') ...[
                        DropdownButton<int>(
                          value: _selQuarter,
                          dropdownColor: AppColors.white,
                          items: List.generate(4, (i) => i + 1)
                              .map((q) =>
                              DropdownMenuItem(value: q, child: Text('Quý $q')))
                              .toList(),
                          onChanged: (v) => setState(() => _selQuarter = v!),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selYear,
                          dropdownColor: AppColors.white,
                          items: _years.map((y) =>
                              DropdownMenuItem(value: y, child: Text('$y')))
                              .toList(),
                          onChanged: (v) => setState(() => _selYear = v!),
                        ),
                      ] else
                        if (_mode == 'Năm') ...[
                          DropdownButton<int>(
                            value: _selYear,
                            dropdownColor: AppColors.white,
                            items: _years.map((y) =>
                                DropdownMenuItem(value: y, child: Text('$y')))
                                .toList(),
                            onChanged: (v) => setState(() => _selYear = v!),
                          ),
                        ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- TAB 1: Biểu đồ ---
                  if (bills.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (chartData.values.every((v) => v == 0))
                    const Center(child: Text('Chưa có dữ liệu để vẽ biểu đồ'))
                  else
                    RevenueChart(data: chartData, color: AppColors.primary),
                  // --- TAB 2: Danh sách (UI cũ) ---
                  Column(
                    children: [
                      // StatCard row giữ nguyên
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Phiếu phạt',
                              count: bookPenalties.length,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Doanh thu',
                              amount: data.fold<double>(
                                  0, (s, b) => s + b.amountReceived),
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Danh sách chi tiết
                      Expanded(
                        child: ListView(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Phiếu phạt – ${NumberFormat.currency(
                                  locale: 'vi_VN', symbol: '₫').format(
                                  bookPenalties.fold<double>(
                                      0, (s, b) => s + b.amountReceived))}',
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            ...bookPenalties.map((b) =>
                                InkWell(
                                  onTap: () =>
                                      _showBillDetailDialog(context, b),
                                  child: _BillTile(bill: b),
                                )),
                            const Divider(height: 32,
                                color: AppColors.inactive),
                            Text(
                              'Hóa đơn phòng – ${NumberFormat.currency(
                                  locale: 'vi_VN', symbol: '₫').format(
                                  roomInvoices.fold<double>(
                                      0, (s, b) => s + b.amountReceived))}',
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            ...roomInvoices.map((b) =>
                                InkWell(
                                  onTap: () =>
                                      _showBillDetailDialog(context, b),
                                  child: _BillTile(bill: b),
                                )),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    // Nếu amount != null thì hiển thị tiền, ngược lại hiển thị count
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

class RevenueChart extends StatelessWidget {
  final Map<String, double> data;
  final Color color;

  const RevenueChart({
    Key? key,
    required this.data,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = data.entries.toList();

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            // trục dưới (X-axis)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) return const SizedBox();
                  // chỉ trả về Text, không cần SideTitleWidget
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      items[idx].key,
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                  );
                },
              ),
            ),
            // trục trái (Y-axis)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calcInterval(items),
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // value là Y/1000
                  final text = (value * 1000).toInt().toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(text, style: TextStyle(fontSize: 10, color: color)),
                  );
                },
              ),
            ),
            // ẩn trục trên và phải
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                items.length,
                    (i) => FlSpot(i.toDouble(), items[i].value / 1000),
              ),
              isCurved: false,
              barWidth: 2,
              dotData: FlDotData(show: true),
              color: color, // đúng param hiện tại
            ),
          ],
        ),
      )
    );
  }

  double _calcInterval(List<MapEntry<String,double>> items) {
    if (items.isEmpty) return 1;
    final maxY = items.map((e) => e.value).reduce((a,b)=> a>b ? a : b);
    final raw = (maxY / 5) / 1000;
    return raw <= 0 ? 1 : raw;
  }

}
/// Tile hiển thị Bill ngắn gọn
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
