// lib/pages/borrow_return_review/widgets/ReturnList.dart

import 'package:flutter/material.dart';
import '../../../model/BorowRequest.dart';
import '../../../model/ReturnRequest.dart';
import '../../../model/Book.dart';
import 'ReturnTitle.dart';

class ReturnList extends StatelessWidget {
  final List<BorrowRequest> borrows;
  final List<ReturnRequest> returns;
  final List<Book> books;
  final String filter;

  final String sortField; // 'date' hoặc 'user'
  final bool sortAsc;
  final ValueChanged<String?> onSortFieldChanged;
  final VoidCallback onToggleSortOrder;

  const ReturnList({
    Key? key,
    required this.borrows,
    required this.returns,
    required this.books,
    required this.filter,
    required this.sortField,
    required this.sortAsc,
    required this.onSortFieldChanged,
    required this.onToggleSortOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final q = filter.toLowerCase();

    // 1) Lọc chỉ completed
    var list = returns.where((r) => r.status == 'completed').toList();

    // 2) Sort đúng cách: dùng r1, r2
    list.sort((r1, r2) {
      int cmp;
      if (sortField == 'user') {
        // Lấy email user từ BorrowRequest tương ứng
        final ua = borrows
            .firstWhere((br) => br.id == r1.borrowRequestId)
            .userEmail ??
            '';
        final ub = borrows
            .firstWhere((br) => br.id == r2.borrowRequestId)
            .userEmail ??
            '';
        cmp = ua.compareTo(ub);
      } else {
        // Theo ngày trả
        cmp = r1.returnDate!.compareTo(r2.returnDate!);
      }
      return sortAsc ? cmp : -cmp;
    });

    // 3) Áp dụng filter text
    list = list.where((r) {
      final matched = borrows.where((b) => b.id == r.borrowRequestId).toList();
      final borrow = matched.isNotEmpty ? matched.first : null;
      final user = (borrow?.userEmail ?? borrow?.userId ?? '').toLowerCase();
      final title = (borrow?.bookTitle ?? borrow?.bookId ?? '').toLowerCase();
      return user.contains(q) || title.contains(q);
    }).toList();

    if (list.isEmpty) {
      return Center(child: Text('Không có “Đã trả”.'));
    }

    return Column(
      children: [
        // ==== TOOLBAR ====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: sortField,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
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

        // ==== LIST ====
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];

              // Tìm BorrowRequest tương ứng
              final brList = borrows.where((b) => b.id == r.borrowRequestId).toList();
              final borrow = brList.isNotEmpty ? brList.first : null;

              // Tìm Book tương ứng
              final bkList = books.where((bk) => bk.id == borrow?.bookId).toList();
              final book = bkList.isNotEmpty ? bkList.first : null;

              return ReturnTile(
                request: r,
                borrow: borrow,
                book: book,
                overdueFeePerDay: 0,
                userId: null,
              );
            },
          ),
        ),
      ],
    );
  }
}
