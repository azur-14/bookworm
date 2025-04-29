import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  late TextEditingController priceCtl;

  late int newTotal;
  late int newAvail;

  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    titleCtl = TextEditingController(text: widget.book.title);
    authorCtl = TextEditingController(text: widget.book.author);
    pubCtl = TextEditingController(text: widget.book.publisher);
    yearCtl = TextEditingController(text: widget.book.publishYear.toString());
    descCtl = TextEditingController(text: widget.book.description ?? '');
    priceCtl = TextEditingController(text: widget.book.price.toString());

    newTotal = widget.book.totalQuantity;
    newAvail = widget.book.availableQuantity;

    if (widget.book.image.isNotEmpty) {
      try {
        imageBytes = base64Decode(widget.book.image);
      } catch (_) {}
    }
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
            _input(priceCtl, 'Price', number: true),
            _dropdownCategory(),
            _quantityEditor('Total Quantity', true),
            _quantityEditor('Available Quantity', false),
            _input(descCtl, 'Description'),
            _pickImageButton(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _handleUpdateBook,
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

  Widget _pickImageButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('Choose Image'),
            onPressed: _pickImage,
          ),
          const SizedBox(height: 8),
          if (imageBytes != null)
            Image.memory(imageBytes!, width: 100, height: 100, fit: BoxFit.cover),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  Future<void> _handleUpdateBook() async {
    try {
      // Validate dữ liệu
      if (titleCtl.text.trim().isEmpty ||
          authorCtl.text.trim().isEmpty ||
          pubCtl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đủ Title, Author và Publisher')),
        );
        return;
      }

      final year = int.tryParse(yearCtl.text);
      if (year == null || year < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Năm xuất bản phải là số hợp lệ')),
        );
        return;
      }

      final price = double.tryParse(priceCtl.text);
      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giá sách phải là số hợp lệ')),
        );
        return;
      }

      final updated = Book(
        id: widget.book.id,
        image: imageBytes != null ? base64Encode(imageBytes!) : widget.book.image,
        title: titleCtl.text.trim(),
        author: authorCtl.text.trim(),
        publisher: pubCtl.text.trim(),
        publishYear: year,
        price: price,
        categoryId: widget.book.categoryId,
        totalQuantity: newTotal,
        availableQuantity: newAvail,
        description: descCtl.text.trim(),
        timeCreate: widget.book.timeCreate,
      );

      await updateBookOnServer(updated);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> updateBookOnServer(Book book) async {
    final resp = await http.put(
      Uri.parse('http://localhost:3003/api/books/${book.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(book.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Update failed: ${resp.body}');
    }
  }
}
