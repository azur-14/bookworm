import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:http/http.dart' as http;

import '../../model/BookItem.dart';
import '../../model/Shelf.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({Key? key}) : super(key: key);
  @override
  _BookManagementPageState createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;

  final List<Book> _books = [];
  final List<Category> _categories = [];
  final Map<String, List<BookItem>> _mockBookItems = {};

  final List<Shelf> _shelves = [
    Shelf(
      id: 1,
      name: 'Shelf A',
      description: 'First floor shelf',
      capacityLimit: 100,
      currentCount: 20,
      timeCreate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Shelf(
      id: 2,
      name: 'Shelf B',
      description: 'Second floor shelf',
      capacityLimit: 80,
      currentCount: 50,
      timeCreate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Shelf(
      id: 3,
      name: 'Shelf C',
      description: 'Basement shelf',
      capacityLimit: 50,
      currentCount: 5,
      timeCreate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
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

  // 2) Khi fetch, nếu đã có trong cache thì trả cache, nếu không thì tạo mới
  Future<List<BookItem>> fetchBookItems(String bookId) async {
    if (_mockBookItems.containsKey(bookId)) {
      return _mockBookItems[bookId]!;
    }
    await Future.delayed(const Duration(milliseconds: 500)); // simulate latency

    final items = [
      BookItem(id: '1', bookId: bookId, shelfId: 1, shelfName: 'Shelf A',
          status: 'available', damageImage: null,
          timeCreate: DateTime.now().subtract(const Duration(days: 10))),
      BookItem(id: '2', bookId: bookId, shelfId: 2, shelfName: 'Shelf B',
          status: 'borrowed', damageImage: null,
          timeCreate: DateTime.now().subtract(const Duration(days: 8))),
      BookItem(id: '3', bookId: bookId, shelfId: 3, shelfName: 'Shelf C',
          status: 'damaged', damageImage: 'https://example.com/damage3.jpg',
          timeCreate: DateTime.now().subtract(const Duration(days: 5))),
      BookItem(id: '4', bookId: bookId, shelfId: null, shelfName: '',
          status: 'lost', damageImage: null,
          timeCreate: DateTime.now().subtract(const Duration(days: 2))),
    ];

    _mockBookItems[bookId] = items;
    return items;
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _catName(String id) {
    return _categories
        .firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown'))
        .name;
  }

  Widget _buildTextField(TextEditingController ctl, String label,
      {bool numericOnly = false}) {
    return TextField(
      controller: ctl,
      keyboardType: numericOnly ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController ctl, String label) =>
      _buildTextField(ctl, label, numericOnly: true);

  // --- 1) Add Book ---
  Future<void> _showAddBookDialog() async {
    final titleCtl = TextEditingController();
    final authorCtl = TextEditingController();
    final pubCtl = TextEditingController();
    final yearCtl = TextEditingController();
    final descCtl = TextEditingController();
    final imgCtl = TextEditingController();
    final qtyCtl = TextEditingController(text: '1');
    Category? selCat = _categories.isNotEmpty ? _categories.first : null;
    String status = 'available';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.library_add_outlined, color: Colors.brown),
                const SizedBox(width: 8),
                Text('Add Book',
                    style: TextStyle(
                        color: Colors.brown[700], fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _buildTextField(titleCtl, 'Title'),
                const SizedBox(height: 12),
                _buildTextField(authorCtl, 'Author'),
                const SizedBox(height: 12),
                _buildTextField(pubCtl, 'Publisher'),
                const SizedBox(height: 12),
                _buildNumberField(yearCtl, 'Publish Year'),
                const SizedBox(height: 12),
                DropdownButtonFormField<Category>(
                  value: selCat,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) => setStateDialog(() => selCat = c),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                _buildTextField(descCtl, 'Description'),
                const SizedBox(height: 12),
                _buildTextField(imgCtl, 'Image URL'),
                const SizedBox(height: 12),
                _buildNumberField(qtyCtl, 'Total Quantity'),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  try {
                    final totalQty = int.tryParse(qtyCtl.text) ?? 1;
                    final newBook = Book(
                      id: '', // server sẽ gán
                      image: imgCtl.text,
                      title: titleCtl.text,
                      author: authorCtl.text,
                      publisher: pubCtl.text,
                      publishYear: int.tryParse(yearCtl.text) ?? 0,
                      categoryId: selCat!.id,
                      totalQuantity: totalQty,
                      availableQuantity: totalQty,
                      description: descCtl.text.isEmpty ? null : descCtl.text,
                      timeCreate: DateTime.now(),
                    );
                    await addBookToServer(newBook);
                    await _loadData();
                    Navigator.pop(ctx);
                  } catch (e) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('ADD'),
              ),
            ],
          );
        },
      ),
    );
  }
    //updateBook
  Future<void> _showUpdateBookDialog(Book b) async {
    // Controllers cho các trường text thông thường
    final titleCtl = TextEditingController(text: b.title);
    final authorCtl = TextEditingController(text: b.author);
    final pubCtl = TextEditingController(text: b.publisher);
    final yearCtl = TextEditingController(text: b.publishYear.toString());
    final descCtl = TextEditingController(text: b.description ?? '');
    final imgCtl = TextEditingController(text: b.image);

    // Giá trị ban đầu và biến state cho total/available
    final int originalTotal = b.totalQuantity;
    int newTotal = b.totalQuantity;
    int newAvail = b.availableQuantity;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.edit_outlined, color: Colors.brown),
                const SizedBox(width: 8),
                Text(
                  'Update Book',
                  style: TextStyle(
                      color: Colors.brown[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Các trường text thông thường
                _buildTextField(titleCtl, 'Title'),
                const SizedBox(height: 12),
                _buildTextField(authorCtl, 'Author'),
                const SizedBox(height: 12),
                _buildTextField(pubCtl, 'Publisher'),
                const SizedBox(height: 12),
                _buildNumberField(yearCtl, 'Publish Year'),
                const SizedBox(height: 12),
                DropdownButtonFormField<Category>(
                  value: _categories.firstWhere((c) => c.id == b.categoryId),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) => setStateDialog(() {
                    // không cần local selCat ngoài, ta chỉ dùng id c.id khi cập nhật
                  }),
                ),
                const SizedBox(height: 12),

                // === Total Quantity: chỉ tăng, min = originalTotal ===
                Row(
                  children: [
                    const Text(
                      'Total Quantity:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),

                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: newTotal > originalTotal
                          ? () => setStateDialog(() => newTotal--)
                          : null,
                    ),

                    Text('$newTotal',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),

                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setStateDialog(() {
                        newTotal++;
                        // Nếu available lớn hơn total mới thì clamp lại
                        if (newAvail > newTotal) newAvail = newTotal;
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // === Available Quantity: không vượt quá newTotal ===
                Row(
                  children: [
                    const Text(
                      'Available Quantity:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),

                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: newAvail > 0
                          ? () => setStateDialog(() => newAvail--)
                          : null,
                    ),

                    Text('$newAvail',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),

                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: newAvail < newTotal
                          ? () => setStateDialog(() => newAvail++)
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description và Image URL
                _buildTextField(descCtl, 'Description'),
                const SizedBox(height: 12),
                _buildTextField(imgCtl, 'Image URL'),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  // Khởi tạo object mới với newTotal và newAvail
                  final updated = Book(
                    id: b.id,
                    image: imgCtl.text,
                    title: titleCtl.text,
                    author: authorCtl.text,
                    publisher: pubCtl.text,
                    publishYear: int.tryParse(yearCtl.text) ?? b.publishYear,
                    categoryId: b.categoryId,
                    totalQuantity: newTotal,
                    availableQuantity: newAvail,
                    description: descCtl.text.isEmpty ? null : descCtl.text,
                    timeCreate: b.timeCreate,
                  );

                  try {
                    await updateBookOnServer(updated);
                    await _loadData();
                    Navigator.pop(ctx);
                  } catch (e) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('UPDATE'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _showViewBookDialog(Book b) async {
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.brown),
                const SizedBox(width: 8),
                Text('Book: ${b.title}', style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 600, height: 400,
              child: FutureBuilder<List<BookItem>>(
                future: fetchBookItems(b.id),
                builder: (ctx3, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final items = snap.data!;
                  return SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Shelf')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: items.map((it) {
                        return DataRow(cells: [
                          DataCell(Text(it.id.toString())),
                          DataCell(Text(it.shelfName)),
                          DataCell(Text(it.status)),
                          DataCell(Text(DateFormat('yyyy-MM-dd').format(it.timeCreate))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await _showUpdateBookItemDialog(it);
                                setStateDialog(() {}); // reload FutureBuilder
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUpdateBookItemDialog(BookItem it) async {
    // Lấy Shelf ban đầu từ _shelves (orElse dựng Shelf từ it.shelfName)
    Shelf? selShelf = it.shelfId != null
        ? _shelves.firstWhere(
          (s) => s.id == it.shelfId,
      orElse: () => Shelf(
        id: it.shelfId!,
        name: it.shelfName,
        description: '',
        capacityLimit: 0,
        currentCount: 0,
        timeCreate: it.timeCreate,
      ),
    )
        : null;

    String status = it.status;
    String? damage = it.damageImage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            title: const Text('Update Book Item'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              // 1) Shelf dropdown từ _shelves
              DropdownButtonFormField<Shelf>(
                value: selShelf,
                decoration: const InputDecoration(
                  labelText: 'Shelf',
                  border: OutlineInputBorder(),
                ),
                items: _shelves.map((shelf) {
                  return DropdownMenuItem(
                    value: shelf,
                    child: Text(shelf.name),
                  );
                }).toList(),
                onChanged: (shelf) => setStateDialog(() => selShelf = shelf),
              ),
              const SizedBox(height: 12),

              // 2) Status dropdown
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['available', 'borrowed', 'damaged', 'lost']
                    .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                    .toList(),
                onChanged: (st) => setStateDialog(() => status = st!),
              ),
              const SizedBox(height: 12),

              // 3) Damage Image URL
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Damage Image URL',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: damage),
                onChanged: (v) => damage = v,
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  // Build lại BookItem với shelf mới
                  final updated = BookItem(
                    id: it.id,
                    bookId: it.bookId,
                    shelfId: selShelf?.id,
                    shelfName: selShelf?.name ?? '',
                    status: status,
                    damageImage: damage,
                    timeCreate: it.timeCreate,
                  );
                  try {
                    await updateBookItemOnServer(updated);
                    Navigator.pop(ctx);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 3) Khi “cập nhật” gọi vào đây để chỉnh cache (không thực sự lên server)
  Future<void> updateBookItemOnServer(BookItem item) async {
    await Future.delayed(const Duration(milliseconds: 200)); // simulate latency
    final list = _mockBookItems[item.bookId]!;
    final idx = list.indexWhere((it) => it.id == item.id);
    if (idx >= 0) list[idx] = item;
  }
  // --- 4) Delete Book ---
  void _delete(Book b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Delete "${b.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL')),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await deleteBookOnServer(b.id);
                await _loadData();
                Navigator.pop(ctx);
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 100,
            child: Text('$label:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.brown[700]))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
      ]),
    );
  }

  Widget _table() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Author')),
            DataColumn(label: Text('Publisher')),
            DataColumn(label: Text('Year')),
            DataColumn(label: Text('Cat')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Avail')),
            DataColumn(label: Text('Action')),
          ], rows: _books.map((b) {
            return DataRow(cells: [
              DataCell(Text(b.id)),
              DataCell(Text(b.title, overflow: TextOverflow.ellipsis)),
              DataCell(Text(b.author)),
              DataCell(Text(b.publisher)),
              DataCell(Text(b.publishYear.toString())),
              DataCell(Text(_catName(b.categoryId))),
              DataCell(Text(b.totalQuantity.toString())),
              DataCell(Text(b.availableQuantity.toString())),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed: () => _showViewBookDialog(b)),
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.brown),
                    onPressed: () => _showUpdateBookDialog(b)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _delete(b)),
              ])),
            ]);
          }).toList()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('hh:mm a').format(_currentTime);
    final formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: Container(
          color: const Color(0xFFFFF3EB),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Book Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ElevatedButton.icon(
                onPressed: _showAddBookDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Book'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    foregroundColor: const Color(0xFFFFF3EB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by ID or Title',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (q) {
                    // làm lọc client-side nếu cần
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _table(),
                ),
              ),
            )
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.centerRight,
        child: Text('$formattedDate, $formattedTime'),
      )
    ]);
  }

  // ----------- API Calls -----------
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

  Future<void> updateBookOnServer(Book b) async {
    final resp = await http.put(
      Uri.parse('http://localhost:3003/api/books/${b.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(b.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Update book failed: ${resp.body}');
    }
  }

  Future<void> deleteBookOnServer(String id) async {
    final resp =
    await http.delete(Uri.parse('http://localhost:3003/api/books/$id'));
    if (resp.statusCode != 200) {
      throw Exception('Delete book failed: ${resp.body}');
    }
  }
}
