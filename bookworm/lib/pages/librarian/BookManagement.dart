import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/Book.dart';
import '../../model/Category.dart';
//viet ham load Category
//viet ham load Book
//update _showAddBookDialog()
//update  _showViewBookDialog
//update  _showUpdateBookDialog
//update _delete
class BookManagementPage extends StatefulWidget {
  const BookManagementPage({Key? key}) : super(key: key);

  @override
  _BookManagementPageState createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;

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
    // ...
  ];

  final List<Category> _categories = [
    Category(id: 'cat1', name: 'Educational'),
    Category(id: 'cat2', name: 'Design'),
    Category(id: 'cat3', name: 'Fiction'),
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool numericOnly = false,    // ← make sure this is here
      }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: numericOnly ? TextInputType.number : TextInputType.text,
    );
  }

  String _catName(String id) {
    return _categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown')).name;
  }
// 1) Add Book
  Future<void> _showAddBookDialog() async {
    final titleCtl     = TextEditingController();
    final authorCtl    = TextEditingController();
    final pubCtl       = TextEditingController();
    final yearCtl      = TextEditingController();
    final statusCtl    = TextEditingController();
    Category? selCat   = _categories.first;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            // Giảm insetPadding nếu bạn muốn dialog to hơn nữa
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.library_add_outlined, color: Colors.brown),
                const SizedBox(width: 8),
                Text('Add Book',
                    style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
              ],
            ),

            // Bọc content trong Container có height cố định hoặc tỉ lệ
            content: Container(
              // 80% chiều cao màn hình
              height: MediaQuery.of(context).size.height * 0.8,
              // 80% chiều rộng màn hình
              width: MediaQuery.of(context).size.width * 0.8,
              // Cho phép cuộn nếu nội dung vượt quá
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(titleCtl, 'Title'),
                    const SizedBox(height: 12),
                    _buildTextField(authorCtl, 'Author'),
                    const SizedBox(height: 12),
                    _buildTextField(pubCtl, 'Publisher'),
                    const SizedBox(height: 12),
                    _buildTextField(yearCtl, 'Publish Year', numericOnly: true),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Category>(
                      value: selCat,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c.name));
                      }).toList(),
                      onChanged: (c) => setStateDialog(() => selCat = c),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(statusCtl, 'Status (e.g. available, borrowed)'),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _books.add(Book(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtl.text,
                      author: authorCtl.text,
                      publisher: pubCtl.text,
                      publishYear: yearCtl.text,
                      categoryId: selCat!.id,
                      status: statusCtl.text,
                      timeCreate: DateTime.now(),
                    ));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('ADD'),
              ),
            ],
          );
        },
      ),
    );
  }


// 2) Update Book
  Future<void> _showUpdateBookDialog(Book b) async {
    final titleCtl  = TextEditingController(text: b.title);
    final authorCtl = TextEditingController(text: b.author);
    final pubCtl    = TextEditingController(text: b.publisher);
    final yearCtl   = TextEditingController(text: b.publishYear);
    final statusCtl = TextEditingController(text: b.status);
    Category? selCat = _categories.firstWhere(
          (c) => c.id == b.categoryId,
      orElse: () => _categories.first,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.edit_outlined, color: Colors.brown),
                const SizedBox(width: 8),
                Text('Update Book',
                    style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(titleCtl, 'Title'),
                  const SizedBox(height: 12),
                  _buildTextField(authorCtl, 'Author'),
                  const SizedBox(height: 12),
                  _buildTextField(pubCtl, 'Publisher'),
                  const SizedBox(height: 12),
                  _buildTextField(yearCtl, 'Publish Year', numericOnly: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Category>(
                    value: selCat,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name));
                    }).toList(),
                    onChanged: (c) => setStateDialog(() => selCat = c),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(statusCtl, 'Status (e.g. available, borrowed)'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    b.title       = titleCtl.text;
                    b.author      = authorCtl.text;
                    b.publisher   = pubCtl.text;
                    b.publishYear = yearCtl.text;
                    b.categoryId  = selCat!.id;
                    b.status      = statusCtl.text;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('UPDATE'),
              ),
            ],
          );
        },
      ),
    );
  }

// 3) View Book
  Future<void> _showViewBookDialog(Book b) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.visibility_outlined, color: Colors.brown),
            const SizedBox(width: 8),
            Text('View Book',
                style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReadOnlyField('ID', b.id),
            _buildReadOnlyField('Title', b.title),
            _buildReadOnlyField('Author', b.author),
            _buildReadOnlyField('Publisher', b.publisher),
            _buildReadOnlyField('Year', b.publishYear),
            _buildReadOnlyField('Category', _catName(b.categoryId)),
            _buildReadOnlyField('Status', b.status),
            _buildReadOnlyField('Created', DateFormat('MMM dd, yyyy').format(b.timeCreate)),
          ],
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
      ),
    );
  }

// 4) Delete Confirmation
  void _delete(Book b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete "${b.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() => _books.remove(b));
              Navigator.pop(ctx);
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Author')),
              DataColumn(label: Text('Publisher')),
              DataColumn(label: Text('Year')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: _books.map((b) {
              return DataRow(cells: [
                DataCell(Text(b.id)),
                DataCell(Text(b.title, overflow: TextOverflow.ellipsis)),
                DataCell(Text(b.author)),
                DataCell(Text(b.publisher)),
                DataCell(Text(b.publishYear)),
                DataCell(Text(_catName(b.categoryId))),
                DataCell(Text(b.status)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => _showViewBookDialog(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.brown),
                      onPressed: () => _showUpdateBookDialog(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _delete(b),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    final String formattedTime = DateFormat('hh:mm a').format(_currentTime);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFFFF3EB),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Book Management',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddBookDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        foregroundColor: Color(0xFFFFF3EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by ID or Name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _table(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

