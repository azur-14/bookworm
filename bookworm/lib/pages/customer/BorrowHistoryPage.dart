import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:bookworm/model/BorowRequest.dart';
import 'package:bookworm/model/ReturnRequest.dart';
import 'package:bookworm/theme/AppColor.dart';

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
    _loadFakeData();
  }

  void _loadFakeData() {
    books = List.generate(4, (i) => Book(
      id: 'b00$i',
      image: 'https://picsum.photos/200/30${i + 1}',
      title: 'Book $i',
      author: 'Author $i',
      publisher: 'Pub $i',
      publishYear: 2020 + i,
      categoryId: 'cat$i',
      totalQuantity: 3,
      availableQuantity: 1,
      timeCreate: DateTime(2021, i + 1, 1),
    ));

    bookItems = List.generate(8, (i) => BookItem(
      id: 'copy00$i',
      bookId: 'b00${i % 4}',
      shelfId: 1,
      shelfName: 'Shelf A',
      status: 'borrowed',
      timeCreate: DateTime(2023, i + 1, 1),
    ));

    borrowRequests = [
      BorrowRequest(id: 'br001', userId: widget.userId, bookCopyId: 'copy000', status: 'pending', requestDate: DateTime(2024, 4, 1), dueDate: DateTime(2024, 4, 10), bookId: 'b000'),
      BorrowRequest(id: 'br002', userId: widget.userId, bookCopyId: 'copy001', status: 'approved', requestDate: DateTime(2024, 3, 1), dueDate: DateTime(2024, 3, 15), bookId: 'b001'),
      BorrowRequest(id: 'br003', userId: widget.userId, bookCopyId: 'copy002', status: 'approved', requestDate: DateTime(2024, 2, 1), dueDate: DateTime(2024, 2, 15), bookId: 'b002'),
      BorrowRequest(id: 'br004', userId: widget.userId, bookCopyId: 'copy003', status: 'rejected', requestDate: DateTime(2024, 1, 1), dueDate: DateTime(2024, 1, 10), bookId: 'b003'),
      BorrowRequest(id: 'br005', userId: widget.userId, bookCopyId: 'copy004', status: 'approved', requestDate: DateTime(2024, 4, 5), dueDate: DateTime(2024, 4, 12), bookId: 'b000'),
    ];

    returnRequests = [
      ReturnRequest(id: 'rr003', borrowRequestId: 'br003', returnDate: DateTime(2024, 2, 20), status: 'completed', returnImage: ''),
      ReturnRequest(id: 'rr005', borrowRequestId: 'br005', returnDate: DateTime(2024, 4, 11), status: 'completed', returnImage: 'damaged.jpg'),
      ReturnRequest(id: 'rr002', borrowRequestId: 'br002', returnDate: DateTime(2024, 3, 10), status: 'processing', returnImage: ''),
    ];
  }

  String getCombinedStatus(BorrowRequest r, ReturnRequest? ret) {
    if (r.status == 'pending') return 'Chờ duyệt';
    if (r.status == 'rejected') return 'Từ chối';

    if (r.status == 'approved') {
      if (ret == null) return 'Đang mượn';
      if (ret.status == 'processing') return 'Đang trả';
      if (ret.status == 'overdue') return 'Trả quá hạn';
      if (ret.status == 'completed') {
        if (ret.returnImage.isNotEmpty) return 'Hư hao';
        if (ret.returnDate.isAfter(r.dueDate)) return 'Trả quá hạn';
        return 'Đã trả';
      }
    }
    return 'Không rõ';
  }

  BookItem? getCopy(String copyId) {
    try {
      return bookItems.firstWhere((b) => b.id == copyId);
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
            Text('Hạn trả: ${formatDate(r.dueDate)}'),
            if (ret != null) Text('Trả: ${formatDate(ret.returnDate)}'),
            Text('Trạng thái: $status', style: TextStyle(color: getStatusColor(status))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
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
              child: SizedBox(
                width: 50,
                height: 70,
                child: book.image.isNotEmpty
                    ? Image.network(book.image, fit: BoxFit.cover)
                    : Container(color: Colors.grey[300], child: const Icon(Icons.book)),
              ),
            ),
            title: Text(book.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mượn: ${formatDate(r.requestDate)}'),
                Text('Hạn: ${formatDate(r.dueDate)}'),
                if (ret != null) Text('Trả: ${formatDate(ret.returnDate)}'),
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
}
