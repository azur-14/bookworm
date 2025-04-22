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

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  final List<Book> _books = [];
  final List<Category> _categories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
    if (result == true) _loadData();
  }

  void _showUpdateBookDialog(Book book) async {
    final result = await showDialog(
      context: context,
      builder: (_) => BookDialogUpdate(book: book, categories: _categories),
    );
    if (result == true) _loadData();
  }

  void _showViewBookDialog(Book book) {
    showDialog(
      context: context,
      builder: (_) => BookDialogDetail(book: book),
    );
  }

  void _deleteBook(Book book) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Delete "${book.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          )
        ],
      ),
    );
    if (confirmed == true) {
      await deleteBookOnServer(book.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);
    final formattedDate = DateFormat('MMM dd, yyyy').format(now);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Book Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search title or author...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddBookDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _bookTable(),
                ),
              ),
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
      final q = _searchQuery.trim();
      return q.isEmpty || b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
    );
  }

  // ---------------- BOOK API (gộp vào luôn) ----------------
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

  Future<void> addBookToServer(Book b) async {
    final resp = await http.post(
      Uri.parse('http://localhost:3003/api/books'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(b.toJson()),
    );
    if (resp.statusCode != 201) {
      throw Exception('Add book failed: ${resp.body}');
    }
  }

  Future<void> deleteBookOnServer(String id) async {
    final resp = await http.delete(Uri.parse('http://localhost:3003/api/books/$id'));
    if (resp.statusCode != 200) {
      throw Exception('Delete failed: ${resp.body}');
    }
  }
}
