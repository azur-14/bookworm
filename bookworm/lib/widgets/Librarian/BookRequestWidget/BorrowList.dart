// lib/pages/borrow_return_review/widgets/BorrowList.dart

import 'package:flutter/material.dart';
import '../../../model/BorowRequest.dart';
import '../../../model/ReturnRequest.dart';
import '../../../model/Book.dart';
import 'BorrowTitle.dart';

class BorrowList extends StatelessWidget {
  final List<BorrowRequest> borrows;
  final List<ReturnRequest> returns;
  final List<Book> books;
  final String status;
  final String filter;
  final int overdueFeePerDay;
  final String? userId;

  // Mới: sortField & sortAsc
  final String sortField; // 'date' hoặc 'title'
  final bool sortAsc;

  // Callbacks để parent update sort
  // Trong BorrowList (tương tự ReturnList, HistoryList)
  final ValueChanged<String?> onSortFieldChanged;
  final VoidCallback onToggleSortOrder;

  const BorrowList({
    Key? key,
    required this.borrows,
    required this.returns,
    required this.books,
    required this.status,
    required this.filter,
    required this.overdueFeePerDay,
    required this.userId,
    required this.sortField,
    required this.sortAsc,
    required this.onSortFieldChanged,
    required this.onToggleSortOrder,
  }) : super(key: key);

  String _combinedStatus(BorrowRequest b) {
    final retList = returns.where((r) => r.borrowRequestId == b.id).toList();
    final ret = retList.isNotEmpty ? retList.first : null;
    if (b.status == 'pending') return 'Chờ duyệt';
    if (b.status == 'rejected') return 'Từ chối';
    if (b.status == 'approved' && ret == null) return 'Chờ nhận';
    if ((b.status == 'received' && ret == null) ||
        (b.status == 'received' && ret?.status == 'processing')) {
      return 'Đang mượn';
    }
    if (ret?.status == 'completed') return 'Đã trả';
    return 'Không rõ';
  }

  @override
  Widget build(BuildContext context) {
    final q = filter.toLowerCase();

    // 1) Lọc theo status + filter text
    var list = borrows.where((b) {
      if (_combinedStatus(b) != status) return false;
      final title = (b.bookTitle ?? b.bookId).toLowerCase();
      final user = (b.userEmail ?? b.userId).toLowerCase();
      return title.contains(q) || user.contains(q);
    }).toList();

    // 2) Sắp xếp theo sortField + sortAsc
    list.sort((a, b) {
      int cmp;
      if (sortField == 'title') {
        final ta = (a.bookTitle ?? a.bookId).toLowerCase();
        final tb = (b.bookTitle ?? b.bookId).toLowerCase();
        cmp = ta.compareTo(tb);
      } else {
        cmp = a.requestDate.compareTo(b.requestDate);
      }
      return sortAsc ? cmp : -cmp;
    });

    // 3) Nếu rỗng
    if (list.isEmpty) {
      return Center(child: Text('Không có “$status”.'));
    }

    return Column(
      children: [
        // ===== TOOLBAR =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              DropdownButton<String>(
                value: sortField,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'title', child: Text('Title')),
                ],
                onChanged: onSortFieldChanged,
              ),
              IconButton(
                icon: Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: onToggleSortOrder,
              ),
            ],
          ),
        ),

        // ===== LIST =====
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final borrow = list[i];
              final retList = returns.where((r) => r.borrowRequestId == borrow.id).toList();
              final matchedReturns = returns.where((r) => r.borrowRequestId == borrow.id).toList();
              final ret = matchedReturns.isNotEmpty ? matchedReturns.first : null;
              final bookList = books.where((bk) => bk.id == borrow.bookId).toList();
              final book = bookList.isNotEmpty ? bookList.first : null;

              return BorrowTile(
                request: borrow,
                retRequest: ret,
                book: book,
                overdueFeePerDay: overdueFeePerDay,
                userId: userId,
              );
            },
          ),
        ),
      ],
    );
  }
}
