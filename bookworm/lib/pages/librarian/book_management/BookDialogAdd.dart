import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:http/http.dart' as http;


class BookDialogAdd extends StatefulWidget {
  final List<Category> categories;

  const BookDialogAdd({super.key, required this.categories});

  @override
  State<BookDialogAdd> createState() => _BookDialogAddState();
}

class _BookDialogAddState extends State<BookDialogAdd> {
  final titleCtl = TextEditingController();
  final authorCtl = TextEditingController();
  final pubCtl = TextEditingController();
  final yearCtl = TextEditingController();
  final descCtl = TextEditingController();
  final imgCtl = TextEditingController();
  final qtyCtl = TextEditingController(text: '1');
  Category? selCat;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) selCat = widget.categories.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Book'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _input(titleCtl, 'Title'),
          _input(authorCtl, 'Author'),
          _input(pubCtl, 'Publisher'),
          _input(yearCtl, 'Publish Year', number: true),
          _input(descCtl, 'Description'),
          _input(imgCtl, 'Image URL'),
          _input(qtyCtl, 'Total Quantity', number: true),
          const SizedBox(height: 12),
          DropdownButtonFormField<Category>(
            value: selCat,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (c) => setState(() => selCat = c),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _handleAddBook,
          child: const Text('ADD'),
        ),
      ],
    );
  }

  Widget _input(TextEditingController ctl, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: ctl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Future<void> _handleAddBook() async {
    try {
      final totalQty = int.tryParse(qtyCtl.text) ?? 1;
      final newBook = Book(
        id: '',
        title: titleCtl.text,
        author: authorCtl.text,
        publisher: pubCtl.text,
        publishYear: int.tryParse(yearCtl.text) ?? 0,
        categoryId: selCat?.id ?? '',
        totalQuantity: totalQty,
        availableQuantity: totalQty,
        image: imgCtl.text,
        description: descCtl.text,
        timeCreate: DateTime.now(),
      );
      await addBookToServer(newBook);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ------------------ API đặt tại đây ------------------
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
}
