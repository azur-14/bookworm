import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookDialogAdd extends StatefulWidget {
  final List<Category> categories;

  const BookDialogAdd({Key? key, required this.categories}) : super(key: key);

  @override
  _BookDialogAddState createState() => _BookDialogAddState();
}

class _BookDialogAddState extends State<BookDialogAdd> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtl;
  late TextEditingController _authorCtl;
  late TextEditingController _pubCtl;
  late TextEditingController _yearCtl;
  late TextEditingController _descCtl;
  late TextEditingController _priceCtl;
  late TextEditingController _qtyCtl;

  Category? _selCat;
  Uint8List? _imageBytes;
  String _adminId = 'unknown_admin';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _adminId = prefs.getString('userId') ?? 'unknown_admin';
      });
    });
    _titleCtl = TextEditingController();
    _authorCtl = TextEditingController();
    _pubCtl = TextEditingController();
    _yearCtl = TextEditingController();
    _descCtl = TextEditingController();
    _priceCtl = TextEditingController();
    _qtyCtl = TextEditingController(text: '1');
    _selCat = widget.categories.isNotEmpty ? widget.categories.first : null;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _authorCtl.dispose();
    _pubCtl.dispose();
    _yearCtl.dispose();
    _descCtl.dispose();
    _priceCtl.dispose();
    _qtyCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.all(24),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: const Text(
        'Add New Book',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_titleCtl, 'Title', validator: (v) => v!.isEmpty ? 'Required' : null),
              _buildTextField(_authorCtl, 'Author', validator: (v) => v!.isEmpty ? 'Required' : null),
              _buildTextField(_pubCtl, 'Publisher', validator: (v) => v!.isEmpty ? 'Required' : null),
              _buildTextField(_yearCtl, 'Publish Year', keyboard: TextInputType.number, validator: (v) {
                final yr = int.tryParse(v!);
                return (yr == null || yr < 0) ? 'Invalid year' : null;
              }),
              _buildTextField(_descCtl, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_priceCtl, 'Price', keyboard: TextInputType.number, validator: (v) {
                      final p = double.tryParse(v!);
                      return (p == null || p < 0) ? 'Invalid price' : null;
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_qtyCtl, 'Quantity', keyboard: TextInputType.number, validator: (v) {
                      final q = int.tryParse(v!);
                      return (q == null || q < 1) ? 'Must be >=1' : null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                value: _selCat,
                decoration: _inputDecoration('Category'),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _selCat = c),
                validator: (v) => v == null ? 'Choose a category' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _handleAddBook,
          child: const Text('ADD'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildTextField(
      TextEditingController ctl,
      String label, {
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: _inputDecoration(label),
        validator: validator,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.image),
          label: const Text('Choose Image'),
          onPressed: _pickImage,
        ),
        if (_imageBytes != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imageBytes!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _handleAddBook() async {
    if (!_formKey.currentState!.validate()) return;

    final newBook = Book(
      id: '',
      title: _titleCtl.text.trim(),
      author: _authorCtl.text.trim(),
      publisher: _pubCtl.text.trim(),
      publishYear: int.parse(_yearCtl.text),
      price: double.parse(_priceCtl.text),
      categoryId: _selCat!.id,
      totalQuantity: int.parse(_qtyCtl.text),
      availableQuantity: int.parse(_qtyCtl.text),
      image: _imageBytes != null ? base64Encode(_imageBytes!) : '',
      description: _descCtl.text.trim(),
      timeCreate: DateTime.now(),
    );

    try {
      await addBookToServer(newBook);
      await _logAction(
        actionType: 'CREATE',
        targetId: newBook.title,
        description: 'Thêm sách mới: ${newBook.title} (${newBook.author})',
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: \$e')),
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
      throw Exception('Add book failed: \${resp.body}');
    }
  }

  Future<void> _logAction({
    required String actionType,
    required String targetId,
    required String description,
  }) async {
    final url = Uri.parse('http://localhost:3004/api/logs');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'adminId': _adminId,
        'actionType': actionType,
        'targetType': 'Book',
        'targetId': targetId,
        'description': description,
      }),
    );
  }
}