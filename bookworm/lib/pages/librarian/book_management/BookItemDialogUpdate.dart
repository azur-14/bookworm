import 'package:flutter/material.dart';
import 'package:bookworm/model/Shelf.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  String _adminId = 'unknown_admin';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _adminId = prefs.getString('userId') ?? 'unknown_admin';
      });
    });
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
              await updateBookItem(widget.bookItem.id, selShelf?.id, status, damageUrl);
              await _logAction(
                actionType: 'UPDATE',
                targetId: widget.bookItem.id.toString(),
                description: 'Cập nhật BookItem ID ${widget.bookItem.id} với status "$status", shelf ${selShelf?.name ?? "none"}',
              );
              Navigator.pop(context, true); // thông báo thành công
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cập nhật thất bại: $e')),
              );
            }
          },
          child: const Text('SAVE'),
        )
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

  Future<BookItem> fetchBookItemById(int id) async {
    final res = await http.get(Uri.parse('http://localhost:3003/api/bookcopies/$id'));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return BookItem.fromJson(data);
    } else {
      throw Exception('Failed to load BookItem');
    }
  }

  Future<void> updateBookItem(String id, int? shelfId, String status, String? damageImage) async {
    final res = await http.put(
      Uri.parse('http://localhost:3003/api/bookcopies/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'shelf_id': shelfId,
        'status': status,
        'damage_image': damageImage,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update BookItem: ${res.body}');
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
        'adminId': 'admin_update_item', // hoặc dùng ID thực nếu có login
        'actionType': actionType,
        'targetType': 'BookItem',
        'targetId': targetId,
        'description': description,
      }),
    );
  }
}

