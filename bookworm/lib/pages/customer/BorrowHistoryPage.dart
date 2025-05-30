import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _searchCtl = TextEditingController();
  String _searchText = '';
  final List<String> _sortOptions = [
    'Ngày mới nhất',
    'Ngày cũ nhất',
    'Tên A-Z',
    'Tên Z-A',
  ];
  String _sortOption = 'Ngày mới nhất';
  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtl.addListener(() {
      setState(() => _searchText = _searchCtl.text.toLowerCase());
    });
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
    }
    throw Exception('Failed to load book items');
  }

  Future<List<Book>> fetchBooks() async {
    final res = await http.get(Uri.parse('http://localhost:3003/api/books'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Book>.from(data.map((e) => Book.fromJson(e)));
    }
    throw Exception('Failed to load books');
  }

  Future<List<BorrowRequest>> fetchBorrowRequests(String userId) async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/borrowRequest/user/$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<BorrowRequest>.from(data.map((e) => BorrowRequest.fromJson(e)));
    }
    throw Exception('Failed to load borrow requests');
  }

  Future<List<ReturnRequest>> fetchReturnRequests(String userId) async {
    final res = await http.get(Uri.parse('http://localhost:3002/api/returnRequest/user/$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<ReturnRequest>.from(data.map((e) => ReturnRequest.fromJson(e)));
    }
    throw Exception('Failed to load return requests');
  }

  List<BookItem> getBookItemsUsedInBorrowRequests(
      List<BorrowRequest> requests,
      List<BookItem> items,
      ) {
    final ids = requests.map((r) => r.bookCopyId).toSet();
    return items.where((item) => ids.contains(item.id.toString())).toList();
  }

  /// Kết hợp status theo thứ tự:
  /// pending → Chờ duyệt
  /// cancelled → Đã hủy
  /// rejected → Từ chối
  /// approved & no ReturnRequest → Chờ nhận
  /// processing → Đang mượn
  /// overdue → Trả quá hạn
  /// completed → Đã trả / Hư hao
  String getCombinedStatus(BorrowRequest r, ReturnRequest? ret) {
    if (r.status == 'pending') return 'Chờ duyệt';
    if (r.status == 'cancelled') return 'Đã hủy';
    if (r.status == 'rejected') return 'Từ chối';
    if (r.status == 'approved' && ret == null) return 'Chờ nhận';
    if (ret != null && ret.status == 'processing') return 'Đang mượn';
    if (ret != null && ret.status == 'overdue') return 'Trả quá hạn';
    if (ret != null && ret.status == 'completed') {
      if (ret.condition != null && ret.condition!.isNotEmpty) {
        return 'Hư hao';
      }
      // unwrap returnDate và dueDate trước khi so sánh
      if (ret.returnDate != null && r.dueDate != null
          && ret.returnDate!.isAfter(r.dueDate!)) {
        return 'Trả quá hạn';
      }
      return 'Đã trả';
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
      case 'Chờ duyệt':   return Colors.orange;
      case 'Chờ nhận':   return Colors.blueGrey;
      case 'Đang mượn':   return Colors.blueAccent;
      case 'Trả quá hạn': return Colors.redAccent;
      case 'Hư hao':      return Colors.deepOrange;
      case 'Đã trả':      return Colors.green;
      case 'Từ chối':     return Colors.red;
      case 'Đã hủy':     return Colors.grey;
      default:            return Colors.grey;
    }
  }

  IconData getStatusIcon(String s) {
    switch (s) {
      case 'Chờ duyệt':   return Icons.hourglass_top;
      case 'Chờ nhận':    return Icons.inventory_2;
      case 'Đang mượn':   return Icons.book;
      case 'Trả quá hạn': return Icons.warning;
      case 'Hư hao':      return Icons.report_problem;
      case 'Đã trả':      return Icons.assignment_turned_in;
      case 'Từ chối':     return Icons.cancel;
      case 'Đã hủy':      return Icons.delete_forever;
      default:            return Icons.help;
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
            Text('Yêu cầu: ${formatDate(r.requestDate)}'),
            if (r.receiveDate != null) Text('Nhận: ${formatDate(r.receiveDate!)}'),
            Text('Hạn trả: ${formatDate(r.dueDate!)}'),
            if (ret != null) ...[
              if (ret.returnDate != null)
                Text('Trả: ${formatDate(ret.returnDate!)}')
              else
                Text('Trả: (chưa có ngày trả)',
                    style: TextStyle(fontStyle: FontStyle.italic)),
            ],

            const SizedBox(height: 8),
            Text('Trạng thái: $status', style: TextStyle(color: getStatusColor(status))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  List<BorrowRequest> getByCombinedStatus(String statusLabel) {
    if (statusLabel == 'Tất cả') {
      return List<BorrowRequest>.from(borrowRequests)
        ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
    }
    return borrowRequests.where((r) {
      final ret = getReturnStatus(r.id!);
      return getCombinedStatus(r, ret) == statusLabel;
    }).toList();
  }

  Widget _buildList(String statusLabel) {
    // 1) Lọc theo status
    var list = getByCombinedStatus(statusLabel);
    // 2) Lọc theo search text (book title)
    list = list.where((r) {
      final copy = getCopy(r.bookCopyId);
      final book = copy != null ? getBook(copy.bookId) : null;
      return book != null &&
          book.title.toLowerCase().contains(_searchText);
    }).toList();
    // 3) Sort theo lựa chọn
    list.sort((a, b) {
      switch (_sortOption) {
        case 'Ngày mới nhất':
          return b.requestDate.compareTo(a.requestDate);
        case 'Ngày cũ nhất':
          return a.requestDate.compareTo(b.requestDate);
        case 'Tên A-Z': {
          final ba = getBook(getCopy(a.bookCopyId)!.bookId)!.title;
          final bb = getBook(getCopy(b.bookCopyId)!.bookId)!.title;
          return ba.compareTo(bb);
        }
        case 'Tên Z-A': {
          final ba = getBook(getCopy(a.bookCopyId)!.bookId)!.title;
          final bb = getBook(getCopy(b.bookCopyId)!.bookId)!.title;
          return bb.compareTo(ba);
        }
        default:
          return b.requestDate.compareTo(a.requestDate);
      }
    });

    if (list.isEmpty) {
      return const Center(child: Text('Không có dữ liệu.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, index) {
        final r = list[index];
        final copy = getCopy(r.bookCopyId);
        final book = copy != null ? getBook(copy.bookId) : null;
        final ret = getReturnStatus(r.id!);
        final combined = getCombinedStatus(r, ret);

        if (book == null || copy == null) return const SizedBox();

        // nút/hình status hoặc Hủy
        Widget trailing;
        if (combined == 'Chờ duyệt' || combined == 'Chờ nhận') {
          trailing = ElevatedButton(
            onPressed: () => cancelBorrowRequest(r),
            child: const Text('Hủy'),
          );
        } else {
          trailing = Column(
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
          );
        }

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
                Text('Ngày yêu cầu: ${formatDate(r.requestDate)}'),
                Text('Ngày nhận:   ${formatDate(r.receiveDate!)}'),
                Text('Hạn trả:     ${formatDate(r.dueDate!)}'),
              ],
            ),
            trailing: trailing,
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Tất cả','Chờ duyệt','Chờ nhận','Đang mượn','Trả quá hạn',
      'Hư hao','Đã trả','Từ chối','Đã hủy',
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          // đổi màu text và icon của AppBar thành be:
          foregroundColor: AppColors.background,
          title: const Text('Borrowing History'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.background,
            unselectedLabelColor: AppColors.inactive,
            indicatorColor: AppColors.background,
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: Column(
          children: [
            // ===== Search & Sort row =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchCtl,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên sách',
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _sortOption,
                      items: _sortOptions.map((opt) =>
                          DropdownMenuItem(value: opt, child: Text(opt))
                      ).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sortOption = v);
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      iconEnabledColor: AppColors.primary,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Nội dung chính =====
            Expanded(
              child: TabBarView(
                children: tabs.map((status) => _buildList(status)).toList(),
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

  Future<void> cancelBorrowRequest(BorrowRequest r) async {
    final borrowId = r.id!;
    final bookCopyId = r.bookCopyId;

    try {
      // 1. Cập nhật trạng thái BorrowRequest
      final borrowUrl = Uri.parse('http://localhost:3002/api/borrowRequest/$borrowId/status');
      final borrowRes = await http.put(
        borrowUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'newStatus': 'cancelled',
          'changedBy': widget.userId,
        }),
      );

      // 2. Cập nhật trạng thái BookCopy
      final copyUrl = Uri.parse('http://localhost:3003/api/bookcopies/$bookCopyId/status');
      final copyRes = await http.put(
        copyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'newStatus': 'available'}),
      );

      // 3. Kiểm tra thành công và cập nhật UI
      if (borrowRes.statusCode == 200 && copyRes.statusCode == 200) {
        setState(() => r.status = 'cancelled');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy yêu cầu và cập nhật sách thành công.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy yêu cầu: ${borrowRes.body} / ${copyRes.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi yêu cầu: $e')),
      );
    }
  }

}
