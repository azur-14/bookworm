import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:flutter/material.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:bookworm/pages/customer/BookDetailPage.dart';
import 'package:bookworm/model/BorowRequest.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookShelfPage extends StatefulWidget {
  const BookShelfPage({Key? key}) : super(key: key);

  @override
  _BookShelfPageState createState() => _BookShelfPageState();
}

class _BookShelfPageState extends State<BookShelfPage> {
  final TextEditingController _searchCtl = TextEditingController();
  String _filter = '';
  bool _gridView = true;
  String? _selectedCategory;
  String? _selectedPublisher;


  final List<Book> _books = [];
  final List<Category> _categories = [];

  final List<String> _publishers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtl.addListener(() {
      setState(() => _filter = _searchCtl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  String _catName(String id) =>
      _categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown')).name;

  bool hasAvailableCopy(int available) {
    if (available>0) return true;
    else return false;
  }

  Future<List<Book>> fetchBooks() async {
    final response = await http.get(Uri.parse('http://localhost:3003/api/books'));

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load books: ${response.body}');
    }
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('http://localhost:3003/api/categories'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((j) => Category.fromJson(j)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<void> _loadData() async {
    try {
      final books = await fetchBooks();
      final categories = await fetchCategories();

      final publishers = books.map((b) => b.publisher).toSet().toList()..sort();

      setState(() {
        _books
          ..clear()
          ..addAll(books);
        _categories
          ..clear()
          ..addAll(categories);
        _publishers
          ..clear()
          ..addAll(publishers);
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _books.where((b) {
      final txt = _filter;
      final okText = b.title.toLowerCase().contains(txt) || b.author.toLowerCase().contains(txt);
      final okCat = _selectedCategory == null || b.categoryId == _selectedCategory;
      final okPub = _selectedPublisher == null || b.publisher == _selectedPublisher;
      return okText && okCat && okPub;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              child: Row(
                children: [
                  Text(
                    'Browse & Borrow',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _gridView ? Icons.list : Icons.grid_view,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _gridView = !_gridView),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(builder: (ctx, box) {
                final isNarrow = box.maxWidth < 600;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isNarrow ? box.maxWidth : 300,
                      child: TextField(
                        controller: _searchCtl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search title or author',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isNarrow ? box.maxWidth : 180,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                    ),
                    SizedBox(
                      width: isNarrow ? box.maxWidth : 180,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPublisher,
                        decoration: InputDecoration(
                          labelText: 'Publisher',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ..._publishers.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                        ],
                        onChanged: (v) => setState(() => _selectedPublisher = v),
                      ),
                    ),
                  ],
                );
              }),
            ),
            Expanded(
              child: _gridView ? _buildGridView(filtered) : _buildListView(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 200 / 410,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) => _buildGridItem(books[i]),
    );
  }

  Widget _buildGridItem(Book b) {
    final statusLabel = hasAvailableCopy(b.availableQuantity) ? 'Available' : 'Unavailable';
    final statusColor = hasAvailableCopy(b.availableQuantity) ? Colors.green : Colors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(book: b, categories: _categories),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: b.image.isNotEmpty
                  ? Image.network(b.image, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
            ),
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('by ${b.author}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_catName(b.categoryId)} · ${b.publishYear}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const Spacer(),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Book> books) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final b = books[idx];
        final statusLabel = hasAvailableCopy(b.availableQuantity) ? 'Available' : 'Unavailable';
        final statusColor = hasAvailableCopy(b.availableQuantity) ? Colors.green : Colors.red;

        return Card(
          child: ListTile(
            title: Text(b.title),
            subtitle: Text('by ${b.author}'),
            trailing: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailPage(book: b, categories: _categories),
              ),
            ),
          ),
        );
      },
    );
  }
}
