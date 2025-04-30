import 'package:flutter/material.dart';
import 'package:bookworm/model/Shelf.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class BookItemDialogUpdate extends StatefulWidget {
  final BookItem bookItem;

  const BookItemDialogUpdate({super.key, required this.bookItem});

  @override
  State<BookItemDialogUpdate> createState() => _BookItemDialogUpdateState();
}

class _BookItemDialogUpdateState extends State<BookItemDialogUpdate> {
  List<Shelf> _shelves = [];

  Shelf? selShelf;
  String status = 'available';
  String? damageUrl;

  @override
  void initState() {
    super.initState();
    _loadShelves();
    status = widget.bookItem.status;
    damageUrl = widget.bookItem.damageImage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Book Item'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<Shelf>(
              value: selShelf,
              decoration: const InputDecoration(labelText: 'Shelf', border: OutlineInputBorder()),
              items: _shelves.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (s) => setState(() => selShelf = s),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['available', 'borrowed', 'damaged', 'lost'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => status = s!),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Damage Image URL', border: OutlineInputBorder()),
              controller: TextEditingController(text: damageUrl),
              onChanged: (v) => damageUrl = v,
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () async {
            try {
              await updateBookCopyOnServer(widget.bookItem, selShelf, status, damageUrl);
              Navigator.pop(context, true); // trả về true để biết update thành công
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi cập nhật: $e')),
              );
            }
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  Future<List<Shelf>> fetchAvailableShelves() async {
    final res = await http.get(Uri.parse('http://localhost:3003/api/shelves/available'));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((json) => Shelf.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load available shelves');
    }
  }

  Future<void> _loadShelves() async {
    try {
      final shelves = await fetchAvailableShelves();
      setState(() {
        _shelves
          ..clear()
          ..addAll(shelves);

        // Sau khi load xong _shelves mới set selected shelf
        selShelf = _shelves.isNotEmpty
            ? _shelves.firstWhere(
              (s) => s.id == widget.bookItem.shelfId,
          orElse: () => _shelves.first,
        )
            : null;
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi tải danh sách kệ: $e');
    }
  }

  Future<void> updateBookCopyOnServer(BookItem item, Shelf? shelf, String status, String? damageImage) async {
    final body = {
      'shelf_id': shelf?.id,
      'status': status,
      'damage_image': damageImage,
    };

    final res = await http.put(
      Uri.parse('http://localhost:3003/api/bookcopies/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Update thất bại: ${res.body}');
    }
  }
}

