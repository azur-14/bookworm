import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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
      final response = await http.post(
        Uri.parse('http://localhost:3002/api/borrowRequest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'book_id': widget.book.id,
          'request_date': requestDate.toIso8601String(),
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
    DateTime requestDate = DateTime.now();
    DateTime dueDate = requestDate.add(const Duration(days: 14));

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Mượn sách: ${widget.book.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn ngày mượn:'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: requestDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 0)),
                    lastDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (picked != null) setStateDialog(() => requestDate = picked);
                },
                child: Text('📅 ${DateFormat('yyyy-MM-dd').format(requestDate)}'),
              ),
              const SizedBox(height: 16),
              const Text('Chọn ngày trả dự kiến:'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: requestDate.add(const Duration(days: 1)),
                    lastDate: requestDate.add(const Duration(days: 60)),
                  );
                  if (picked != null) setStateDialog(() => dueDate = picked);
                },
                child: Text('📅 ${DateFormat('yyyy-MM-dd').format(dueDate)}'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () {
                _submitBorrowRequest(requestDate, dueDate);
                Navigator.pop(ctx);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final created = DateFormat('MMM dd, yyyy').format(book.timeCreate);
    final isAvailable = _availableCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: const Color(0xFF594A47),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 100, height: 150, child: _bookImage(book)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        book.title,
                        maxLines: 2,
                        style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('by ${book.author}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${_catName(book.categoryId)} · ${book.publishYear}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Created: $created',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Availability
            Row(
              children: [
                Icon(isAvailable ? Icons.check_circle : Icons.cancel,
                    color: isAvailable ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  isAvailable ? 'In Stock' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Text('$_availableCount/${book.totalQuantity}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            // Description
            if ((book.description ?? '').isNotEmpty) ...[
              const Text('Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(book.description!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
            ],
            // Borrow button
            ElevatedButton.icon(
              icon: Icon(
                  _alreadyBorrowed ? Icons.hourglass_top : Icons.shopping_basket),
              label: Text(
                _alreadyBorrowed ? 'Pending Approval' : 'Borrow ($_availableCount)',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _alreadyBorrowed ? Colors.grey[300] : const Color(0xFF7B4F3C),
                foregroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed:
              (!isAvailable || _alreadyBorrowed) ? null : _showBorrowDialog,
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