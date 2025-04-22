import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:http/http.dart' as http;

class BookDialogUpdate extends StatefulWidget {
  final Book book;
  final List<Category> categories;

  const BookDialogUpdate({
    super.key,
    required this.book,
    required this.categories,
  });

  @override
  State<BookDialogUpdate> createState() => _BookDialogUpdateState();
}

class _BookDialogUpdateState extends State<BookDialogUpdate> {
  late TextEditingController titleCtl;
  late TextEditingController authorCtl;
  late TextEditingController pubCtl;
  late TextEditingController yearCtl;
  late TextEditingController descCtl;
  late TextEditingController imgCtl;

  late int newTotal;
  late int newAvail;

  @override
  void initState() {
    super.initState();
    titleCtl = TextEditingController(text: widget.book.title);
    authorCtl = TextEditingController(text: widget.book.author);
    pubCtl = TextEditingController(text: widget.book.publisher);
    yearCtl = TextEditingController(text: widget.book.publishYear.toString());
    descCtl = TextEditingController(text: widget.book.description ?? '');
    imgCtl = TextEditingController(text: widget.book.image);

    newTotal = widget.book.totalQuantity;
    newAvail = widget.book.availableQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Book'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(titleCtl, 'Title'),
            _input(authorCtl, 'Author'),
            _input(pubCtl, 'Publisher'),
            _input(yearCtl, 'Publish Year', number: true),
            _dropdownCategory(),
            _quantityEditor('Total Quantity', true),
            _quantityEditor('Available Quantity', false),
            _input(descCtl, 'Description'),
            _input(imgCtl, 'Image URL'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () async {
            final updated = Book(
              id: widget.book.id,
              image: imgCtl.text,
              title: titleCtl.text,
              author: authorCtl.text,
              publisher: pubCtl.text,
              publishYear: int.tryParse(yearCtl.text) ?? widget.book.publishYear,
              categoryId: widget.book.categoryId,
              totalQuantity: newTotal,
              availableQuantity: newAvail,
              description: descCtl.text,
              timeCreate: widget.book.timeCreate,
            );
            await updateBookOnServer(updated);
            Navigator.pop(context, true);
          },
          child: const Text('UPDATE'),
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

  Widget _dropdownCategory() {
    final cat = widget.categories.firstWhere((c) => c.id == widget.book.categoryId);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<Category>(
        value: cat,
        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
        items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
        onChanged: (_) {},
      ),
    );
  }

  Widget _quantityEditor(String label, bool isTotal) {
    int current = isTotal ? newTotal : newAvail;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: (isTotal && newTotal > widget.book.totalQuantity) || (!isTotal && current > 0)
                ? () => setState(() {
              if (isTotal) newTotal--;
              else newAvail--;
            })
                : null,
          ),
          Text('$current'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => setState(() {
              if (isTotal) newTotal++;
              else if (newAvail < newTotal) newAvail++;
            }),
          ),
        ],
      ),
    );
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

}
