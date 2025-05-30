import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'BookDialogAdd.dart';
import 'BookDialogUpdate.dart';
import 'BookDialogDetail.dart';
import '../../../model/Book.dart';
import '../../../model/Category.dart';
import '../../../theme/AppColor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  final List<Book> _books = [];
  final List<Category> _categories = [];
  String _searchQuery = '';
  String _adminId = 'unknown_admin';
// filter & sort
  String _selectedCategory = 'All';
  String _sortField = 'Title';
  bool _sortAsc = true;
  final List<String> _sortOptions = ['Title', 'Year'];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _adminId = prefs.getString('userId') ?? 'unknown_admin';
      });
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await fetchCategories();
    final books = await fetchBooks();
    setState(() {
      _categories
        ..clear()
        ..addAll(cats);
      _books
        ..clear()
        ..addAll(books);
    });
  }

  String _catName(String id) {
    return _categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown')).name;
  }

  void _showAddBookDialog() async {
    final result = await showDialog(
      context: context,
      builder: (_) => BookDialogAdd(categories: _categories),
    );
    if (result == true) {
      await _logAction(
        actionType: 'CREATE',
        targetId: 'N/A', // Không có ID trước khi thêm, có thể bỏ qua
        description: 'Thêm sách mới',
      );
      _loadData();
    }
  }

  void _showUpdateBookDialog(Book book) async {
    final result = await showDialog(
      context: context,
      builder: (_) => BookDialogUpdate(book: book, categories: _categories),
    );
    if (result == true) {
      await _logAction(
        actionType: 'UPDATE',
        targetId: book.id,
        description: 'Cập nhật sách "${book.title}" (ID: ${book.id})',
      );
      _loadData();
    }
  }

  void _showViewBookDialog(Book book) {
    showDialog(
      context: context,
      builder: (_) => BookDialogDetail(book: book),
    );
  }

  void _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá "${book.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XOÁ'),
          )
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 1. Gọi xoá trên server
        await deleteBookOnServer(book.id);

        // 2. Cập nhật UI ngay (loại sách khỏi list tại client)
        setState(() {
          _books.removeWhere((b) => b.id == book.id);
        });

        // 3. Ghi log hành động
        await _logAction(
          actionType: 'DELETE',
          targetId: book.id,
          description: 'Xoá sách "${book.title}" (ID: ${book.id})',
        );

        // **Tùy chọn**: nếu bạn vẫn muốn reload toàn bộ từ server:
        await _loadData();

      } catch (e) {
        // Bắt và hiển thị lỗi nếu cần
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xoá thất bại: $e')),
        );
      }
    }
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            style: const TextStyle(color: Colors.black87),
            dropdownColor: Colors.white,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);
    final formattedDate = DateFormat('MMM dd, yyyy').format(now);

    return Scaffold(
      backgroundColor: AppColors.background, // be sáng
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📚 Book Management',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddBookDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Search
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by title or author...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildDropdown(
                      'Category',
                      _selectedCategory,
                      ['All', ..._categories.map((c) => c.name)],
                          (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(width: 16),
                    _buildDropdown(
                      'Sort by',
                      _sortField,
                      _sortOptions,
                          (v) => setState(() => _sortField = v!),
                    ),
                    IconButton(
                      icon:
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                      onPressed: () => setState(() => _sortAsc = !_sortAsc),
                      tooltip: _sortAsc ? 'Sắp xếp tăng' : 'Sắp xếp giảm',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white, // ⭐ Thêm dòng này
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _bookTable(),
                ),
              )

            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('$formattedDate, $formattedTime'),
            ),
          )
        ],
      ),
    );
  }

  Widget _bookTable() {
    final filteredBooks = _books.where((b) {
      final q = _searchQuery.trim().toLowerCase();
      final matchSearch = b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
      final matchCategory = _selectedCategory == 'All' || _catName(b.categoryId) == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();

// Sort logic
    filteredBooks.sort((a, b) {
      final cmp = _sortField == 'Year'
          ? a.publishYear.compareTo(b.publishYear)
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return _sortAsc ? cmp : -cmp;
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1000),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Author')),
              DataColumn(label: Text('Publisher')),
              DataColumn(label: Text('Year')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Available')),
              DataColumn(label: Text('Actions')),
            ],
            rows: filteredBooks.map((book) {
              return DataRow(cells: [
                DataCell(Text(book.id)),
                DataCell(Text(book.title)),
                DataCell(Text(book.author)),
                DataCell(Text(book.publisher)),
                DataCell(Text(book.publishYear.toString())),
                DataCell(Text(_catName(book.categoryId))),
                DataCell(Text(book.totalQuantity.toString())),
                DataCell(Text(book.availableQuantity.toString())),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => _showViewBookDialog(book),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showUpdateBookDialog(book),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBook(book),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ---------------- BOOK API ----------------
  Future<List<Category>> fetchCategories() async {
    final resp = await http.get(Uri.parse('http://localhost:3003/api/categories'));
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((j) => Category.fromJson(j)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<List<Book>> fetchBooks() async {
    final resp = await http.get(Uri.parse('http://localhost:3003/api/books'));
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((j) => Book.fromJson(j)).toList();
    }
    throw Exception('Failed to load books');
  }

  Future<void> deleteBookOnServer(String id) async {
    final resp = await http.delete(Uri.parse('http://localhost:3003/api/books/$id'));
    if (resp.statusCode != 200) {
      throw Exception('Delete failed: ${resp.body}');
    }
  }

  Future<void> _logAction({
    required String actionType,
    required String targetId,
    required String description,
  }) async {
    final url = Uri.parse('http://localhost:3002/api/activityLogs');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'adminId': 'admin_book_manager', // hoặc thay bằng ID thực nếu có đăng nhập
        'actionType': actionType,
        'targetType': 'Book',
        'targetId': targetId,
        'description': description,
      }),
    );
  }
}
