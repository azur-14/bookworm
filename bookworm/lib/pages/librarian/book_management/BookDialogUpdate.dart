import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late TextEditingController totalCtl;
  late TextEditingController availCtl;
  String _adminId = 'unknown_admin';
  int _prevTotalQty = 0;
  int _prevAvailQty = 0;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _adminId = prefs.getString('userId') ?? 'unknown_admin';
      });
    });
    _prevTotalQty = widget.book.totalQuantity;
    _prevAvailQty = widget.book.availableQuantity;
    titleCtl = TextEditingController(text: widget.book.title);
    authorCtl = TextEditingController(text: widget.book.author);
    pubCtl = TextEditingController(text: widget.book.publisher);
    yearCtl = TextEditingController(text: widget.book.publishYear.toString());
    descCtl = TextEditingController(text: widget.book.description ?? '');
    priceCtl = TextEditingController(text: widget.book.price.toString());
    totalCtl = TextEditingController(text: widget.book.totalQuantity.toString());
    availCtl = TextEditingController(text: widget.book.availableQuantity.toString());

    if (widget.book.image.isNotEmpty) {
      try {
        imageBytes = base64Decode(widget.book.image);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    titleCtl.dispose();
    authorCtl.dispose();
    pubCtl.dispose();
    yearCtl.dispose();
    descCtl.dispose();
    priceCtl.dispose();
    totalCtl.dispose();
    availCtl.dispose();
    super.dispose();
  }
  Widget _numberInput(String label, TextEditingController ctl, {
    required int prevValue,
    required void Function(int) onValid,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: ctl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        onChanged: (val) {
          final input = int.tryParse(val) ?? prevValue;
          if (input < prevValue) {
            // Quay về giá trị trước, không cho giảm
            ctl.text = prevValue.toString();
            ctl.selection = TextSelection.fromPosition(
              TextPosition(offset: ctl.text.length),
            );
          } else {
            // Hợp lệ, cập nhật prev và giữ cho Valid
            onValid(input);
          }
        },
      ),
    );
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
            // DÙng _numberInput với prev và onValid riêng
            _numberInput(
              'Total Quantity',
              totalCtl,
              prevValue: _prevTotalQty,
              onValid: (v) => setState(() => _prevTotalQty = v),
            ),
            _numberInput(
              'Available Quantity',
              availCtl,
              prevValue: _prevAvailQty,
              onValid: (v) {
                final cap = _prevTotalQty;
                final safe = v > cap ? cap : v;
                setState(() => _prevAvailQty = safe);
                if (safe != v) {
                  // nếu nhập > tổng, reset về cap
                  availCtl.text = safe.toString();
                  availCtl.selection = TextSelection.fromPosition(
                    TextPosition(offset: availCtl.text.length),
                  );
                }
              },
            ),
            _input(descCtl, 'Description'),
            _pickImageButton(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(onPressed: _handleUpdateBook, child: const Text('UPDATE')),
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
    // validate required fields
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

    final totalQty = int.tryParse(totalCtl.text) ?? widget.book.totalQuantity;
    final availQty = int.tryParse(availCtl.text)?.clamp(0, totalQty) ?? totalQty;

    final updated = Book(
      id: widget.book.id,
      image: imageBytes != null ? base64Encode(imageBytes!) : widget.book.image,
      title: titleCtl.text.trim(),
      author: authorCtl.text.trim(),
      publisher: pubCtl.text.trim(),
      publishYear: year,
      price: price,
      categoryId: widget.book.categoryId,
      totalQuantity: totalQty,
      availableQuantity: availQty,
      description: descCtl.text.trim(),
      timeCreate: widget.book.timeCreate,
    );

    try {
      await updateBookOnServer(updated);
      await _logAction(
        actionType: 'UPDATE',
        targetId: updated.id,
        description: 'Cập nhật sách "${updated.title}" (${updated.id})',
      );
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

  Future<void> _logAction({
    required String actionType,
    required String targetId,
    required String description,
  }) async {
    final url = Uri.parse('http://localhost:3002/api/activityLogs');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'adminId': _adminId, // có thể đổi thành user thực tế nếu dùng login
        'actionType': actionType,
        'targetType': 'Book',
        'targetId': targetId,
        'description': description,
      }),
    );
  }
}
