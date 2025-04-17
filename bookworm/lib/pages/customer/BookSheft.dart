
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';

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

  // Mẫu dữ liệu
  final List<Book> _books = [
    Book(
      id: '1',
      title: 'Flutter for Beginners',
      author: 'Alice Smith',
      publisher: 'Tech Books',
      publishYear: '2020',
      categoryId: 'cat1',
      status: 'available',
      timeCreate: DateTime.parse("2021-01-01T10:00:00"),
    ),
    Book(
      id: '2',
      title: 'Design Patterns',
      author: 'Erich Gamma',
      publisher: 'Addison-Wesley',
      publishYear: '1994',
      categoryId: 'cat2',
      status: 'borrowed',
      timeCreate: DateTime.parse("2021-02-01T10:00:00"),
    ),
    // … thêm sách khác
  ];

  final List<Category> _categories = [
    Category(id: 'cat1', name: 'Educational'),
    Category(id: 'cat2', name: 'Design'),
    Category(id: 'cat3', name: 'Fiction'),
  ];

  List<String> get _publishers =>
      _books.map((b) => b.publisher).toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final filtered = _books.where((b) {
      final t = _filter;
      final okText = b.title.toLowerCase().contains(t) || b.author.toLowerCase().contains(t);
      final okCat = _selectedCategory == null || b.categoryId == _selectedCategory;
      final okPub = _selectedPublisher == null || b.publisher == _selectedPublisher;
      return okText && okCat && okPub;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse & Borrow'),
        backgroundColor: const Color(0xFF594A47),
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _gridView = !_gridView),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search + filters
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchCtl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search title/author',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPublisher,
                    decoration: InputDecoration(
                      labelText: 'Publisher',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ..._publishers.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                    ],
                    onChanged: (v) => setState(() => _selectedPublisher = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nội dung
            Expanded(
              child: _gridView
                  ? _buildGridView(filtered)
                  : _buildListView(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Book> books) {
    return LayoutBuilder(builder: (ctx, box) {
      final width = box.maxWidth;
      // Số cột linh hoạt tuỳ width
      final cross = width > 1000
          ? 4
          : width > 700
          ? 3
          : width > 400
          ? 2
          : 1;

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          // mỗi ô rộng tối đa 300px
          maxCrossAxisExtent: 300,
          // khoảng cách giữa các cột
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          // cố định chiều cao mỗi ô là 260px
          mainAxisExtent: 260,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) => _buildGridItem(books[i]),
      );
    });
  }

  Widget _buildGridItem(Book b) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book, size: 40, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 8),
            AutoSizeText(b.title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(b.author, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              'Cat: ${_catName(b.categoryId)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: b.status == 'available'
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Borrow "${b.title}"')),
              )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B4F3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Borrow'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Book> books) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final b = books[idx];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.book, size: 30, color: Colors.white54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(b.title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('by ${b.author}', style: const TextStyle(color: Colors.grey)),
                      Text('Publisher: ${b.publisher}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: b.status == 'available'
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Borrow "${b.title}"')),
                  )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4F3C),
                    minimumSize: const Size(75, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Borrow', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
