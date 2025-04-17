import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:flutter/material.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:bookworm/pages/customer/BookDetailPage.dart';

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

  // Ví dụ dữ liệu mẫu
  final List<Book> _books = [
    Book(
      id: 'b001',
      image:
      'https://marketplace.canva.com/EAD5HAtO1ec/1/0/1003w/canva-v%C3%A0ng-n%C3%A2u-chim-h%C3%ACnh-minh-h%E1%BB%8Da-nh%E1%BB%8F-b%C3%A9-tr%E1%BA%BB-em-s%C3%A1ch-b%C3%ACa-cptvdrYhx3Y.jpg',
      title: 'Flutter for Beginners',
      author: 'Alice Smith',
      publisher: 'Tech Books',
      publishYear: 2020,
      categoryId: 'cat1',
      totalQuantity: 3,
      availableQuantity: 2,
      description: 'An intro to Flutter.',
      timeCreate: DateTime.parse("2021-01-01T10:00:00"),
    ),
    Book(
      id: 'b002',
      image: '',
      title: 'Design Patterns',
      author: 'Erich Gamma',
      publisher: 'Addison-Wesley',
      publishYear: 1994,
      categoryId: 'cat2',
      totalQuantity: 2,
      availableQuantity: 0,
      description: 'Classic software patterns.',
      timeCreate: DateTime.parse("2021-02-01T10:00:00"),
    ),
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
    // Lọc theo title/author, category, publisher
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
            // 1. HEADER
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
                        color: AppColors.primary),
                    onPressed: () => setState(() => _gridView = !_gridView),
                  ),
                ],
              ),
            ),

            // 2. FILTER BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(builder: (ctx, box) {
                final isNarrow = box.maxWidth < 600;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search field
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

                    // Category filter
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
                          ..._categories.map((c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                    ),

                    // Publisher filter
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
                          ..._publishers.map((p) =>
                              DropdownMenuItem(value: p, child: Text(p))),
                        ],
                        onChanged: (v) => setState(() => _selectedPublisher = v),
                      ),
                    ),
                  ],
                );
              }),
            ),

            // 3. CONTENT
            Expanded(
              child: _gridView ? _buildGridView(filtered) : _buildListView(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Book> books) {
    return LayoutBuilder(
      builder: (ctx, box) {
        // (nếu bạn muốn tính toán dựa trên box.maxWidth để thay đổi gridDelegate thì cứ để ở đây)
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 200 / 410, // giờ ô cao ~350px → info ~350/4 ≃ 87px
          ),
          itemCount: books.length,
          itemBuilder: (_, i) => _buildGridItem(books[i]),
        );
      },
    );}

  // 2. Hàm _buildGridItem với flex 3:1 và Flexible cho info:
  Widget _buildGridItem(Book b) {
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
        // tránh overflow margin hơi xô lệch, thêm clipBehavior
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A) COVER chiếm 3/4 chiều cao
            Expanded(
              flex: 3,
              child: b.image.isNotEmpty
                  ? Image.network(b.image, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
            ),

            // B) INFO + BUTTON: Flexible để chỉ lấy đúng kích thước cần
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
                    Text('by ${b.author}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_catName(b.categoryId)} · ${b.publishYear}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: b.availableQuantity > 0 ? () {/*…*/} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: b.availableQuantity > 0
                            ? const Color(0xFF7B4F3C)
                            : Colors.grey,
                        minimumSize: const Size.fromHeight(32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        b.availableQuantity > 0
                            ? 'Borrow (${b.availableQuantity})'
                            : 'Unavailable',
                        style: const TextStyle(fontSize: 12),
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


  // List view
  Widget _buildListView(List<Book> books) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final b = books[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailPage(book: b, categories: _categories),
            ),
          ),
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 50,
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: b.image.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(b.image, fit: BoxFit.cover),
                    )
                        : const Icon(Icons.book, size: 30, color: Colors.white54),
                  ),
                  const SizedBox(width: 12),
                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          b.title,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text('by ${b.author}',
                            style: const TextStyle(color: Colors.grey)),
                        Text('Publisher: ${b.publisher}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  // Borrow button
                  ElevatedButton(
                    onPressed: b.availableQuantity > 0
                        ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookDetailPage(book: b, categories: _categories),
                      ),
                    )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: b.availableQuantity > 0
                          ? const Color(0xFF7B4F3C)
                          : Colors.grey,
                      minimumSize: const Size(75, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(b.availableQuantity > 0
                        ? 'Borrow (${b.availableQuantity})'
                        : 'Unavailable'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
