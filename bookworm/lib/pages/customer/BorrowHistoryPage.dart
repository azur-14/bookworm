import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:bookworm/model/BorowRequest.dart';
import 'package:bookworm/model/ReturnRequest.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BorrowHistoryPage extends StatefulWidget {
  final String userId;
  const BorrowHistoryPage({super.key, required this.userId});

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  List<Book> books = [];
  List<BookItem> bookItems = [];
  List<BorrowRequest> borrowRequests = [];
  List<ReturnRequest> returnRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fetchedBooks = await fetchBooks();
    final fetchedBorrows = await fetchBorrowRequests(widget.userId);
    final fetchedReturns = await fetchReturnRequests(widget.userId);
    final fetchedItems = await fetchBookItems();

    final usedItems = getBookItemsUsedInBorrowRequests(fetchedBorrows, fetchedItems);

    setState(() {
      books = fetchedBooks;
      borrowRequests = fetchedBorrows;
      returnRequests = fetchedReturns;
      bookItems = usedItems;
    });
  }

  Future<List<BookItem>> fetchBookItems() async {
    final res = await http.get(Uri.parse('http://localhost:3003/api/bookcopies'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<BookItem>.from(data.map((e) => BookItem.fromJson(e)));
    } else {
      throw Exception('Failed to load book items');
    }
  }

  Future<List<Book>> fetchBooks() async {
    final res = await http.get(Uri.parse('http://localhost:3003/api/books'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Book>.from(data.map((e) => Book.fromJson(e)));
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<List<BorrowRequest>> fetchBorrowRequests(String userId) async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/borrowRequest/user/$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<BorrowRequest>.from(data.map((e) => BorrowRequest.fromJson(e)));
    } else {
      throw Exception('Failed to load borrow requests');
    }
  }

  Future<List<ReturnRequest>> fetchReturnRequests(String userId) async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/returnRequest/user/$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<ReturnRequest>.from(data.map((e) => ReturnRequest.fromJson(e)));
    } else {
      throw Exception('Failed to load return requests');
    }
  }

  List<BookItem> getBookItemsUsedInBorrowRequests(
      List<BorrowRequest> requests,
      List<BookItem> items,
      ) {
    final ids = requests.map((r) => r.bookCopyId).toSet();
    return items.where((item) => ids.contains(item.id.toString())).toList();
  }

  String getCombinedStatus(BorrowRequest r, ReturnRequest? ret) {
    if (r.status == 'pending') return 'Chờ duyệt';
    if (r.status == 'rejected') return 'Từ chối';

    if (r.status == 'approved') {
      if (ret == null) return 'Đang mượn';
      if (ret.status == 'processing') return 'Đang trả';
      if (ret.status == 'overdue') return 'Trả quá hạn';
      if (ret.status == 'completed') {
        // dùng returnImageBase64 thay vì returnImage
        if (ret.returnImageBase64 != null &&
            ret.returnImageBase64!.isNotEmpty) {
          return 'Hư hao';
        }

        if (r.dueDate != null && ret.returnDate != null &&
            ret.returnDate!.isAfter(r.dueDate!)) {
          return 'Trả quá hạn';
        }
        return 'Đã trả';
      }
    }
    return 'Không rõ';
  }


  BookItem? getCopy(String copyId) {
    try {
      return bookItems.firstWhere((b) => b.id.toString() == copyId);
    } catch (_) {
      return null;
    }
  }

  Book? getBook(String bookId) {
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  ReturnRequest? getReturnStatus(String borrowRequestId) {
    try {
      return returnRequests.firstWhere((r) => r.borrowRequestId == borrowRequestId);
    } catch (_) {
      return null;
    }
  }

  Color getStatusColor(String s) {
    switch (s) {
      case 'Chờ duyệt': return Colors.orange;
      case 'Đang mượn': return Colors.blueAccent;
      case 'Đang trả': return Colors.purple;
      case 'Trả quá hạn': return Colors.redAccent;
      case 'Hư hao': return Colors.deepOrange;
      case 'Đã trả': return Colors.green;
      case 'Từ chối': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(String s) {
    switch (s) {
      case 'Chờ duyệt': return Icons.hourglass_top;
      case 'Đang mượn': return Icons.book;
      case 'Đang trả': return Icons.swap_horiz;
      case 'Trả quá hạn': return Icons.warning;
      case 'Hư hao': return Icons.report_problem;
      case 'Đã trả': return Icons.assignment_turned_in;
      case 'Từ chối': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  void _showDetail(BorrowRequest r, Book b, String status, ReturnRequest? ret) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(b.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tác giả: ${b.author}'),
            Text('Ngày mượn: ${formatDate(r.requestDate)}'),
            Text('Hạn trả: ${formatDate(r.dueDate!)}'),
            if (ret != null) Text('Trả: ${formatDate(ret.returnDate!)}'),
            Text('Trạng thái: $status', style: TextStyle(color: getStatusColor(status))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  List<BorrowRequest> getByCombinedStatus(String status) {
    return borrowRequests.where((r) {
      final ret = getReturnStatus(r.id ?? '');
      return getCombinedStatus(r, ret) == status;
    }).toList();
  }

  Widget _buildList(String statusLabel) {
    final list = getByCombinedStatus(statusLabel);
    if (list.isEmpty) return const Center(child: Text('Không có dữ liệu.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, index) {
        final r = list[index];
        final copy = getCopy(r.bookCopyId);
        final book = copy != null ? getBook(copy.bookId) : null;
        final ret = getReturnStatus(r.id ?? '');
        final combined = getCombinedStatus(r, ret);

        if (book == null || copy == null) return const SizedBox();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showDetail(r, book, combined, ret),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(width: 50, height: 70, child: _bookImage(book)),
            ),
            title: Text(book.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mượn: ${formatDate(r.requestDate)}'),
                Text('Hạn: ${formatDate(r.dueDate!)}'),
                if (ret != null) Text('Trả: ${formatDate(ret.returnDate!)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(getStatusIcon(combined), color: getStatusColor(combined)),
                const SizedBox(height: 4),
                Text(
                  combined,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getStatusColor(combined),
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Chờ duyệt',
      'Đang mượn',
      'Đang trả',
      'Trả quá hạn',
      'Hư hao',
      'Đã trả',
      'Từ chối',
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử mượn sách'),
          backgroundColor: AppColors.primary,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.primary,
              child: TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: tabs.map((t) => _buildList(t)).toList(),
        ),
      ),
    );
  }

  Widget _bookImage(Book book) {
    if (book.image.isEmpty) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(book.image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, height: 140, width: 100, fit: BoxFit.cover),
      );
    } catch (_) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(book.image, height: 140, width: 100, fit: BoxFit.cover),
      );
    }
  }
}
