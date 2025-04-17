import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:http/http.dart' as http;

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

  // --- 2) Update Book ---
  Future<void> _showUpdateBookDialog(Book b) async {
    final titleCtl = TextEditingController(text: b.title);
    final authorCtl = TextEditingController(text: b.author);
    final pubCtl = TextEditingController(text: b.publisher);
    final yearCtl = TextEditingController(text: b.publishYear.toString());
    final descCtl = TextEditingController(text: b.description ?? '');
    final imgCtl = TextEditingController(text: b.image);
    final totalCtl =
    TextEditingController(text: b.totalQuantity.toString());
    final availCtl =
    TextEditingController(text: b.availableQuantity.toString());
    Category? selCat =
    _categories.firstWhere((c) => c.id == b.categoryId);

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
                Text('Update Book',
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
                _buildNumberField(totalCtl, 'Total Quantity'),
                const SizedBox(height: 12),
                _buildNumberField(availCtl, 'Available Quantity'),
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
                    final updated = Book(
                      id: b.id,
                      image: imgCtl.text,
                      title: titleCtl.text,
                      author: authorCtl.text,
                      publisher: pubCtl.text,
                      publishYear: int.tryParse(yearCtl.text) ?? b.publishYear,
                      categoryId: selCat!.id,
                      totalQuantity:
                      int.tryParse(totalCtl.text) ?? b.totalQuantity,
                      availableQuantity:
                      int.tryParse(availCtl.text) ?? b.availableQuantity,
                      description:
                      descCtl.text.isEmpty ? null : descCtl.text,
                      timeCreate: b.timeCreate,
                    );
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

  // --- 3) View Book ---
  Future<void> _showViewBookDialog(Book b) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.visibility_outlined, color: Colors.brown),
            const SizedBox(width: 8),
            Text('View Book',
                style: TextStyle(
                    color: Colors.brown[700], fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (b.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                Image.network(b.image, height: 150, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            _buildReadOnlyField('ID', b.id),
            _buildReadOnlyField('Title', b.title),
            _buildReadOnlyField('Author', b.author),
            _buildReadOnlyField('Publisher', b.publisher),
            _buildReadOnlyField('Year', b.publishYear.toString()),
            _buildReadOnlyField('Category', _catName(b.categoryId)),
            _buildReadOnlyField(
                'Total Qty', b.totalQuantity.toString()),
            _buildReadOnlyField(
                'Available Qty', b.availableQuantity.toString()),
            _buildReadOnlyField(
                'Created', DateFormat('MMM dd, yyyy').format(b.timeCreate)),
            _buildReadOnlyField('Description', b.description ?? ''),
          ]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
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
