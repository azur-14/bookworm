import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:bookworm/model/BorowRequest.dart';
import 'package:intl/intl.dart';

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
  final List<BookItem> _bookItems = [
    BookItem(
      id: 'copy001',
      bookId: 'b001',
      shelfId: 1,
      status: 'available',
      timeCreate: DateTime(2021, 1, 2),
    ),
    BookItem(
      id: 'copy002',
      bookId: 'b001',
      shelfId: 1,
      status: 'borrowed',
      timeCreate: DateTime(2021, 1, 2),
    ),
    BookItem(
      id: 'copy003',
      bookId: 'b002',
      shelfId: 2,
      status: 'borrowed',
      timeCreate: DateTime(2021, 2, 5),
    ),
  ];

  final List<BorrowRequest> _borrowRequests = [];
  final String _currentUserId = 'u001';

  String _catName(String id) =>
      widget.categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown')).name;

  bool hasAvailableCopy(String bookId) {
    return _bookItems.any((item) => item.bookId == bookId && item.status == 'available');
  }

  BookItem? getFirstAvailableCopy(String bookId) {
    try {
      return _bookItems.firstWhere(
            (item) => item.bookId == bookId && item.status == 'available',
      );
    } catch (_) {
      return null;
    }
  }

  bool isRequestPending(String bookId) {
    final copyIds = _bookItems
        .where((item) => item.bookId == bookId)
        .map((item) => item.id)
        .toSet();
    return _borrowRequests.any((r) => copyIds.contains(r.bookCopyId) && r.status == 'pending');
  }

  void _showBorrowDialog(BuildContext context, Book book) async {
    DateTime dueDate = DateTime.now().add(const Duration(days: 14));

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Mượn sách: ${book.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chọn ngày trả dự kiến:'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setState(() => dueDate = picked);
                    }
                  },
                  child: Text('📅 ${DateFormat('yyyy-MM-dd').format(dueDate)}'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: () {
                  _submitBorrowRequest(book, dueDate);
                  Navigator.pop(context);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          );
        });
      },
    );
  }

  void _submitBorrowRequest(Book book, DateTime dueDate) {
    final item = getFirstAvailableCopy(book.id);
    if (item == null) return;

    setState(() {
      item.status = 'borrowed';
      book.availableQuantity--;

      _borrowRequests.add(
        BorrowRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _currentUserId,
          bookId: book.id,
          bookCopyId: item.id,
          status: 'pending',
          requestDate: DateTime.now(),
          dueDate: dueDate,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Request sent successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final created = DateFormat('MMM dd, yyyy').format(book.timeCreate);
    final isAvailable = hasAvailableCopy(book.id);
    final isPending = isRequestPending(book.id);

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 150,
                    child: book.image.isNotEmpty
                        ? Image.network(book.image, fit: BoxFit.cover)
                        : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 40, color: Colors.white54),
                    ),
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('by ${book.author}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${_catName(book.categoryId)} · ${book.publishYear}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Created: $created', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
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
                Text('${book.availableQuantity}/${book.totalQuantity}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            if ((book.description ?? '').isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(book.description!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              icon: Icon(isPending ? Icons.hourglass_top : Icons.shopping_basket),
              label: Text(
                isPending ? 'Pending Approval' : 'Borrow (${book.availableQuantity})',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? Colors.grey : const Color(0xFF7B4F3C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (!isAvailable || isPending) ? null : () => _showBorrowDialog(context, book),
            ),
          ],
        ),
      ),
    );
  }
}

