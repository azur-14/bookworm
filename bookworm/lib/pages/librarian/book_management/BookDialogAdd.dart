import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';

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
  final priceCtl = TextEditingController();
  final qtyCtl = TextEditingController(text: '1');
  Category? selCat;

  XFile? pickedImage;
  Uint8List? imageBytes;

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
          _pickImageButton(),
          _input(priceCtl, 'Price', number: true),
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
        pickedImage = picked;
        imageBytes = bytes;
      });
    }
  }

  Future<void> _handleAddBook() async {
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

      final totalQty = int.tryParse(qtyCtl.text) ?? 1;

      final newBook = Book(
        id: '',
        title: titleCtl.text.trim(),
        author: authorCtl.text.trim(),
        publisher: pubCtl.text.trim(),
        publishYear: year,
        price: price,
        categoryId: selCat?.id ?? '',
        totalQuantity: totalQty,
        availableQuantity: totalQty,
        image: imageBytes != null ? base64Encode(imageBytes!) : '',
        description: descCtl.text.trim(),
        timeCreate: DateTime.now(),
      );

      await addBookToServer(newBook);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
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
}
