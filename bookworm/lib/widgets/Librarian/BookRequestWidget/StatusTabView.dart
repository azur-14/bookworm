// lib/widgets/Librarian/BookRequestWidget/StatusTabView.dart

import 'package:flutter/material.dart';
import '../../../model/BorowRequest.dart';
import '../../../model/ReturnRequest.dart';
import '../../../model/Book.dart';
import 'BorrowList.dart';
import 'ReturnList.dart';
import 'HistoryList.dart';

class StatusTabView extends StatelessWidget {
  final TabController tabController;
  final String searchQuery;
  final List<String> labels;

  // Dữ liệu từ cha
  final List<BorrowRequest> borrows;
  final List<ReturnRequest> returns;
  final List<Book> books;
  final int overdueFeePerDay;
  final String? userId;

  // Trạng thái sort chung
  final String sortField;               // 'date' hoặc 'title' / 'user'
  final bool sortAsc;                   // true = tăng dần, false = giảm dần
  final ValueChanged<String?> onSortFieldChanged;
  final VoidCallback onToggleSortOrder;
  // Thêm sort cho HistoryList
  final String historySortField;
  final bool   historySortAsc;
  final ValueChanged<String?> onHistorySortFieldChanged;
  final VoidCallback onHistoryToggleSortOrder;

  const StatusTabView({
    Key? key,
    required this.tabController,
    required this.searchQuery,
    required this.labels,
    required this.borrows,
    required this.returns,
    required this.books,
    required this.overdueFeePerDay,
    required this.userId,
    required this.sortField,
    required this.sortAsc,
    required this.onSortFieldChanged,
    required this.onToggleSortOrder,
    required this.historySortField,
    required this.historySortAsc,
    required this.onHistorySortFieldChanged,
    required this.onHistoryToggleSortOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        // 0: Chờ duyệt
        BorrowList(
          borrows: borrows,
          returns: returns,
          books: books,
          status: labels[0],
          filter: searchQuery,
          overdueFeePerDay: overdueFeePerDay,
          userId: userId,
          sortField: sortField,
          sortAsc: sortAsc,
          onSortFieldChanged: onSortFieldChanged,
          onToggleSortOrder: onToggleSortOrder,
        ),

        // 1: Chờ nhận
        BorrowList(
          borrows: borrows,
          returns: returns,
          books: books,
          status: labels[1],
          filter: searchQuery,
          overdueFeePerDay: overdueFeePerDay,
          userId: userId,
          sortField: sortField,
          sortAsc: sortAsc,
          onSortFieldChanged: onSortFieldChanged,
          onToggleSortOrder: onToggleSortOrder,
        ),

        // 2: Đang mượn
        BorrowList(
          borrows: borrows,
          returns: returns,
          books: books,
          status: labels[2],
          filter: searchQuery,
          overdueFeePerDay: overdueFeePerDay,
          userId: userId,
          sortField: sortField,
          sortAsc: sortAsc,
          onSortFieldChanged: onSortFieldChanged,
          onToggleSortOrder: onToggleSortOrder,
        ),

        // 3: Hư hao
        BorrowList(
          borrows: borrows,
          returns: returns,
          books: books,
          status: labels[3],
          filter: searchQuery,
          overdueFeePerDay: overdueFeePerDay,
          userId: userId,
          sortField: sortField,
          sortAsc: sortAsc,
          onSortFieldChanged: onSortFieldChanged,
          onToggleSortOrder: onToggleSortOrder,
        ),

        // 4: Đã trả
        ReturnList(
          borrows: borrows,
          returns: returns,
          books: books,
          filter: searchQuery,
          sortField: sortField,
          sortAsc: sortAsc,
          onSortFieldChanged: onSortFieldChanged,
          onToggleSortOrder: onToggleSortOrder,
        ),

        // 5: Từ chối
        BorrowList(
          borrows: borrows,
          returns: returns,
          books: books,
          status: labels[5],
          filter: searchQuery,
          overdueFeePerDay: overdueFeePerDay,
          userId: userId,
          sortField: sortField,
          sortAsc: sortAsc,
          onSortFieldChanged: onSortFieldChanged,
          onToggleSortOrder: onToggleSortOrder,
        ),

        // 6: Lịch sử
        HistoryList(

          borrows: borrows,
          returns: returns,
          filter: searchQuery,
          sortField: historySortField,
          sortAsc: historySortAsc,
          onSortFieldChanged: onHistorySortFieldChanged,
          onToggleSortOrder: onHistoryToggleSortOrder,
        ),
      ],
    );
  }
}

