import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../theme/AppColor.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  final List<Category> categories;

  const BookDetailPage({
    Key? key,
    required this.book,
    required this.categories,
  }) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  int _availableCount = 0;
  String? _currentUserId;
  bool _alreadyBorrowed = false;

  @override
  void initState() {
    super.initState();
    initUser();
    _loadAvailableCount();
  }

  String _catName(String id) => widget.categories
      .firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown'))
      .name;

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  void initUser() async {
    _currentUserId = await getCurrentUserId();
    await _checkAlreadyBorrowed();
  }

  Future<void> _loadAvailableCount() async {
    try {
      final res = await http.get(Uri.parse(
          'http://localhost:3003/api/bookcopies/available-count/${widget.book.id}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _availableCount = data['availableCount']);
      }
    } catch (e) {
      debugPrint('Error loading available count: $e');
    }
  }

  Future<void> _checkAlreadyBorrowed() async {
    if (_currentUserId == null) return;
    final url = Uri.parse(
        'http://localhost:3002/api/borrowRequest/check/$_currentUserId/${widget.book.id}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() => _alreadyBorrowed = data['alreadyBorrowed'] == true);
    }
  }

  Future<void> _submitBorrowRequest(DateTime requestDate, DateTime dueDate) async {
    try {
      final now = DateTime.now();
      final response = await http.post(
        Uri.parse('http://localhost:3002/api/borrowRequest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'book_id': widget.book.id,
          'receive_date': requestDate.toIso8601String(),
          'request_date': now.toIso8601String(),
          'due_date': dueDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _availableCount--;
          _alreadyBorrowed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Borrow request sent!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showBorrowDialog() async {
    final now = DateTime.now();
    // 1) Chọn cùng lúc borrow & due date với dialog vuông
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDateRange: DateTimeRange(
        start: now,
        end: now.add(const Duration(days: 14)),
      ),
      helpText: 'Chọn khoảng mượn sách',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          // override dialog shape
          dialogTheme: const DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // hoàn toàn vuông
            ),
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.cardBackground,
            onSurface: Colors.black87,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (range == null) return;

    // 2) Confirm dialog vuông
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // hoàn toàn vuông
        ),
        title: const Text('Xác nhận mượn sách'),
        content: Text(
          'Bạn sẽ mượn từ ${DateFormat('yyyy-MM-dd').format(range.start)}\n'
              'đến ${DateFormat('yyyy-MM-dd').format(range.end)}\n'
              '(${range.duration.inDays} ngày).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _submitBorrowRequest(range.start, range.end);
    }
  }



  @override
  Widget build(BuildContext context) {
    final book     = widget.book;
    final created  = DateFormat('MMM dd, yyyy').format(book.timeCreate);
    final available= _availableCount > 0;
    final price    = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0
    ).format(book.price);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        // Cách đơn giản nhất (Flutter 2.0+):
        foregroundColor: AppColors.cardBackground, // sẽ áp cho title và icon

        // Nếu bạn cần control riêng title/icon thì có thể dùng:
        // iconTheme: IconThemeData(color: AppColors.beige),
        // titleTextStyle: TextStyle(
        //   color: AppColors.beige,
        //   fontSize: 20,
        //   fontWeight: FontWeight.bold,
        // ),

        title: const Text('Book Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Ảnh + Tiêu đề trong Card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 100, height: 150,
                        child: _bookImage(book),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            book.title,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'by ${book.author}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.inactive,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2) Category/Year/Created as Chips
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                Chip(
                  backgroundColor: Colors.grey.shade100,
                  label: Text(
                    _catName(book.categoryId),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  avatar: const Icon(Icons.category, color: AppColors.primary),
                ),
                Chip(
                  backgroundColor: Colors.grey.shade100,
                  label: Text(
                    '${book.publishYear}',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  avatar: const Icon(Icons.calendar_today, color: AppColors.primary),
                ),
                Chip(
                  backgroundColor: Colors.grey.shade100,
                  label: Text(
                    'Created: $created',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  avatar: const Icon(Icons.access_time, color: AppColors.primary),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3) Availability
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      available ? Icons.check_circle : Icons.cancel,
                      color: available ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      available ? 'In Stock' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available ? Colors.green : Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_availableCount / ${book.totalQuantity}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4) Description
            if ((book.description ?? '').isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    book.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5) Borrow Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon( _alreadyBorrowed ? Icons.hourglass_top : Icons.shopping_basket ),
                label: Text(
                  _alreadyBorrowed ? 'Pending Approval' : 'Borrow ($_availableCount)',
                ),
                onPressed: (!available || _alreadyBorrowed) ? null : _showBorrowDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadyBorrowed
                      ? AppColors.inactive
                      : AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _bookImage(Book book) {
    if (book.image.isEmpty) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(book.image);
      return Image.memory(bytes, height: 140, width: 100, fit: BoxFit.cover);
    } catch (_) {
      return Image.network(book.image, height: 140, width: 100, fit: BoxFit.cover);
    }
  }
}