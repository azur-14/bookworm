// lib/pages/borrow_return_review/widgets/HistoryList.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/BorowRequest.dart';
import '../../../model/ReturnRequest.dart';
import 'Dialog.dart';
import 'StatCard.dart';

class HistoryList extends StatelessWidget {
  final List<BorrowRequest> borrows;
  final List<ReturnRequest> returns;
  final String filter;

  // Mới: sortField & sortAsc
  final String sortField; // 'request' hoặc 'return'
  final bool sortAsc;
  final ValueChanged<String?> onSortFieldChanged;
  final VoidCallback onToggleSortOrder;

  const HistoryList({
    Key? key,
    required this.borrows,
    required this.returns,
    required this.filter,
    required this.sortField,
    required this.sortAsc,
    required this.onSortFieldChanged,
    required this.onToggleSortOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final q = filter.toLowerCase();

    // Thống kê
    final totalReq = borrows.length;
    final totalRet = returns.length;

    // Danh sách BorrowRequest sau filter text
    var list = borrows.where((b) {
      final title = (b.bookTitle ?? b.bookId).toLowerCase();
      final user  = (b.userEmail ?? b.userId).toLowerCase();
      return title.contains(q) || user.contains(q);
    }).toList();

    // Sort theo requestDate hoặc returnDate
    list.sort((a, b) {
      int cmp;
      if (sortField == 'return') {
        // lấy ngày trả tương ứng (nếu có), null về trước
        final ra = returns.firstWhere(
              (r) => r.borrowRequestId == a.id && r.returnDate != null,
          orElse: () => ReturnRequest(id: '', borrowRequestId: '', status: ''),
        ).returnDate;
        final rb = returns.firstWhere(
              (r) => r.borrowRequestId == b.id && r.returnDate != null,
          orElse: () => ReturnRequest(id: '', borrowRequestId: '', status: ''),
        ).returnDate;
        cmp = (ra ?? DateTime(1900)).compareTo(rb ?? DateTime(1900));
      } else {
        cmp = a.requestDate.compareTo(b.requestDate);
      }
      return sortAsc ? cmp : -cmp;
    });

    return Column(
      children: [
        // Stat Cards
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              StatCard(label: 'Borrowed', count: totalReq),
              const SizedBox(width: 8),
              StatCard(label: 'Returned', count: totalRet),
            ],
          ),
        ),

        const Divider(height: 1),

        // Toolbar filter & sort
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: filter.isEmpty
                    ? const Text('History')
                    : Text('History • Filter: "$filter"'),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: sortField,
                items: const [
                  DropdownMenuItem(value: 'request', child: Text('Req Date')),
                  DropdownMenuItem(value: 'return',  child: Text('Ret Date')),
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

        // List
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Không có lịch sử.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final b = list[i];
              final ret = returns.firstWhere(
                    (r) => r.borrowRequestId == b.id && r.returnDate != null,
                orElse: () => ReturnRequest(id: '', borrowRequestId: '', status: ''),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('Req ${b.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: ${b.userEmail ?? b.userId}'),
                      Text('Requested: ${DateFormat('yyyy-MM-dd').format(b.requestDate)}'),
                      if (ret.returnDate != null)
                        Text('Returned: ${DateFormat('yyyy-MM-dd').format(ret.returnDate!)}'),
                    ],
                  ),
                  // <-- Thêm onTap ở đây để gọi dialog
                  onTap: () => showBorrowReturnInfoDialog(context, b, ret.returnDate != null ? ret : null),
                ),
              );

            },
          ),
        ),
      ],
    );
  }
}
