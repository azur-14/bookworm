import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:bookworm/model/Shelf.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'BookItemDialogUpdate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookDialogDetail extends StatefulWidget {
  final Book book;
  const BookDialogDetail({Key? key, required this.book}) : super(key: key);

  @override
  _BookDialogDetailState createState() => _BookDialogDetailState();
}

class _BookDialogDetailState extends State<BookDialogDetail> {
  List<BookItem> _items = [];
  List<Shelf> _shelves = [];
  final Set<String> _selectedItemIds = {};
  int? _selectedShelfId;
  bool _loadingItems = true;
  bool _loadingShelves = true;
  String _adminId = 'unknown_admin';

  @override
  void initState() {
    super.initState();
    _initAdmin();
    _loadShelves();
    _loadItems();
  }

  Future<void> _initAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _adminId = prefs.getString('userId') ?? 'unknown_admin');
  }

  Future<void> _loadShelves() async {
    setState(() => _loadingShelves = true);
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3003/api/shelves/available'),
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() => _shelves = data.map((j) => Shelf.fromJson(j)).toList());
      }
    } catch (e) {
      debugPrint('❌ Error loading shelves: $e');
    } finally {
      setState(() => _loadingShelves = false);
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3003/api/bookcopies/by-book/${widget.book.id}'),
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() => _items = data.map((j) => BookItem.fromJson(j)).toList());
      }
    } catch (e) {
      debugPrint('❌ Error loading items: $e');
    } finally {
      setState(() => _loadingItems = false);
    }
  }

  String _getShelfName(int id) {
    final s = _shelves.firstWhere(
          (s) => s.id == id,
      orElse: () => Shelf(
        id: 0,
        name: 'Unknown',
        description: '',
        capacityLimit: 0,
        currentCount: 0,
        timeCreate: DateTime.now(),
      ),
    );
    return s.name;
  }

  bool get _canAssign =>
      !_loadingShelves && _selectedShelfId != null && _selectedItemIds.isNotEmpty;

  void _toggleSelectAll() {
    final unassigned = _items.where((i) => i.shelfId == 0).map((i) => i.id.toString());
    setState(() {
      if (_selectedItemIds.length == unassigned.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds
          ..clear()
          ..addAll(unassigned);
      }
    });
  }

  Future<void> _assignSelected() async {
    final ids = _selectedItemIds.toList();
    try {
      final url = Uri.parse('http://localhost:3003/api/bookcopies/bulk-update-shelf');
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ids': ids, 'shelf_id': _selectedShelfId}),
      );
      if (resp.statusCode != 200) throw Exception(resp.body);

      final shelf = _shelves.firstWhere((s) => s.id == _selectedShelfId);
      await _logAction(
        actionType: 'UPDATE',
        targetId: widget.book.id,
        description:
        'Gán ${ids.length} bản sao sách "${widget.book.title}" vào kệ ${shelf.name}',
      );

      await Future.wait([_loadShelves(), _loadItems()]);
      setState(() => _selectedItemIds.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gán ${ids.length} bản sao vào ${shelf.name}')),
      );
    } catch (e) {
      debugPrint('❌ Error assigning shelf: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gán: $e')),
      );
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
        'targetType': 'BookCopy',
        'targetId': targetId,
        'description': description,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        'Book: ${book.title}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 750,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Thông tin sách
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _bookImage(book),
                    const SizedBox(width: 16),
                    Expanded(child: _bookDetailSection(book)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Khung chọn kệ & thao tác
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _toggleSelectAll,
                      child: Text(
                        _selectedItemIds.length ==
                            _items.where((i) => i.shelfId == 0).length
                            ? 'Bỏ chọn tất cả'
                            : 'Chọn tất cả chưa gán',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _loadingShelves
                          ? const SizedBox(
                        height: 32,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                          : DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Chọn kệ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        value: _selectedShelfId,
                        items: _shelves.map((s) {
                          final left = s.capacityLimit - s.currentCount;
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (còn $left)'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedShelfId = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _canAssign ? _assignSelected : null,
                      child: const Text('GÁN ĐỒNG LOẠT'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bảng bản sao sách với scroll dọc + ngang
            Expanded(
              child: _loadingItems
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('Chưa có bản sao nào.'))
                  : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: MaterialStateProperty.all(
                        AppColors.primary.withOpacity(0.1)),
                    columns: const [
                      DataColumn(label: Text('Chọn')),
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Kệ')),
                      DataColumn(label: Text('Ngày tạo')),
                      DataColumn(label: Text('')),
                    ],
                    rows: _items.map((item) {
                      final sel = _selectedItemIds.contains(item.id.toString());
                      final shelfId = item.shelfId ?? 0;
                      return DataRow(
                        selected: sel,
                        onSelectChanged: (v) {
                          setState(() {
                            if (v == true)
                              _selectedItemIds.add(item.id.toString());
                            else
                              _selectedItemIds.remove(item.id.toString());
                          });
                        },
                        cells: [
                          DataCell(Checkbox(
                            value: sel,
                            onChanged: (v) => setState(() {
                              if (v == true)
                                _selectedItemIds.add(item.id.toString());
                              else
                                _selectedItemIds.remove(item.id.toString());
                            }),
                            activeColor: AppColors.primary,
                          )),
                          DataCell(Text(item.id.toString())),
                          DataCell(Text(item.status)),
                          DataCell(Text(
                            shelfId != 0 ? _getShelfName(shelfId) : 'Chưa gán',
                          )),
                          DataCell(Text(
                              DateFormat('yyyy-MM-dd').format(item.timeCreate))),
                          DataCell(IconButton(
                            icon: Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) =>
                                    BookItemDialogUpdate(bookItem: item),
                              );
                              if (ok == true) {
                                await _loadShelves();
                                await _loadItems();
                              }
                            },
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('ĐÓNG', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _bookImage(Book book) {
    if (book.image.isEmpty) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(book.image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, height: 140, width: 100, fit: BoxFit.cover),
      );
    } catch (_) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(book.image, height: 140, width: 100, fit: BoxFit.cover),
      );
    }
  }

  Widget _bookDetailSection(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Author', book.author),
        _infoRow('Publisher', book.publisher),
        _infoRow('Year', book.publishYear.toString()),
        _infoRow('Price', '${book.price.toStringAsFixed(2)} VNĐ'),
        _infoRow('Quantity', '${book.availableQuantity}/${book.totalQuantity}'),
        if (book.description?.isNotEmpty ?? false)
          _infoRow('Description', book.description!),
      ],
    );
  }


  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))
          ),
          Expanded(child: Text(value)),  // đây sẽ wrap tự nhiên
        ],
      ),
    );
  }
}
