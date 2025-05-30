// lib/pages/borrow_return_review/borrow_return_review_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/ReturnRequest.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/model/Book.dart';

import '../../../model/BorowRequest.dart';
import '../../../widgets/Librarian/BookRequestWidget/SearchField.dart';
import '../../../widgets/Librarian/BookRequestWidget/StatusTabView.dart';

class BorrowReturnReviewPage extends StatefulWidget {
  const BorrowReturnReviewPage({Key? key}) : super(key: key);
  @override
  _BorrowReturnReviewPageState createState() => _BorrowReturnReviewPageState();
}

class _BorrowReturnReviewPageState extends State<BorrowReturnReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtl = TextEditingController();

  List<Book> _books = [];
  List<BorrowRequest> _borrows = [];
  List<ReturnRequest> _returns = [];
  List<Bill> _bills = [];
  String? _userId;
  int overdueFeePerDay = 0;
  String _sortField = 'date';
  bool _sortAsc = true;
  final List<String> _labels = [
    'Chờ duyệt',
    'Chờ nhận',
    'Đang mượn',
    'Hư hao',
    'Đã trả',
    'Từ chối',
    'Lịch sử',
  ];
  String _borrowSortField  = 'date';    // cho BorrowList / ReturnList
  bool   _borrowSortAsc    = false;

  String _historySortField = 'request'; // cho HistoryList
  bool   _historySortAsc   = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _labels.length, vsync: this);
    _loadUserPrefs();
    _loadBorrowRequests();
    _loadReturnRequests();
    _loadBooks();
    _loadConfig();
  }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getString('userId'));
  }

  Future<void> _loadConfig() async {
    final res = await http.get(
      Uri.parse('http://localhost:3004/api/systemconfig/2'),
    );
    if (res.statusCode == 200) {
      final cfg = json.decode(res.body);
      setState(() => overdueFeePerDay = int.tryParse(cfg['config_value']) ?? 10000);
    }
  }

  Future<void> _loadBorrowRequests() async {
    final res = await http.get(
      Uri.parse('http://localhost:3002/api/borrowRequest'),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() {
        _borrows =
            data.map((e) => BorrowRequest.fromJson(e)).toList();
      });
    }
  }

  Future<void> _loadReturnRequests() async {
    final res = await http.get(
      Uri.parse('http://localhost:3002/api/returnRequest'),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() {
        _returns =
            data.map((e) => ReturnRequest.fromJson(e)).toList();
      });
    }
  }

  Future<void> _loadBooks() async {
    final res = await http.get(
      Uri.parse('http://localhost:3003/api/books'),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() {
        _books = data.map((e) => Book.fromJson(e)).toList();
      });
    }
  }

  ReturnRequest? _getReturn(BorrowRequest b) {
    for (final r in _returns) {
      if (r.borrowRequestId == b.id) {
        return r;
      }
    }
    return null;
  }


  /// Kết hợp status của borrow + return thành label tiếng Việt
  String _combinedStatus(BorrowRequest b) {
    final ret = _getReturn(b);
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

  List<BorrowRequest> _byStatus(String label) {
    return _borrows
        .where((b) => _combinedStatus(b) == label)
        .toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Duyệt Mượn/Trả Sách',
            style: TextStyle(color: AppColors.white)),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.inactive,
          indicatorColor: AppColors.white,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchField(controller: _searchCtl),
          ),
          Expanded(
            child: StatusTabView(
              tabController: _tabCtrl,
              searchQuery: _searchCtl.text,
              labels: _labels,
              borrows: _borrows,
              returns: _returns,
              books: _books,
              overdueFeePerDay: overdueFeePerDay,
              userId: _userId,

              sortField: _borrowSortField,
              sortAsc:   _borrowSortAsc,
              onSortFieldChanged: (f) {
                if (f != null) setState(() => _borrowSortField = f);
              },
              onToggleSortOrder: () {
                setState(() => _borrowSortAsc = !_borrowSortAsc);
              },

              historySortField: _historySortField,
              historySortAsc:   _historySortAsc,
              onHistorySortFieldChanged: (f) {
                if (f != null) setState(() => _historySortField = f);
              },
              onHistoryToggleSortOrder: () {
                setState(() => _historySortAsc = !_historySortAsc);
              },
            )
          ),
        ],
      ),
    );
  }
}
