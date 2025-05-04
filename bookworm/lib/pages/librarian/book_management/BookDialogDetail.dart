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
  const BookDialogDetail({super.key, required this.book});

  @override
  State<BookDialogDetail> createState() => _BookDialogDetailState();
}

class _BookDialogDetailState extends State<BookDialogDetail> {
  final Map<String, List<BookItem>> _cache = {};
  final Set<String> _selectedItemIds = {};
  int? _selectedShelfId;
  bool _dragSelecting = false;
  String _adminId = 'unknown_admin';

  final List<Shelf> _shelves = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _adminId = prefs.getString('userId') ?? 'unknown_admin';
      });
    });
    _loadShelves();
  }

  String getShelfName(int? shelfId) {
    final shelf = _shelves.firstWhere((s) => s.id == shelfId, orElse: () => Shelf(id: 0, name: 'Unknown', description: '', capacityLimit: 0, currentCount: 0, timeCreate: DateTime.now()));
    return shelf.name;
  }

  bool _isAllSelected(List<BookItem> items) =>
      _selectedItemIds.length == items.where((i) => i.shelfId == 0).length;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AlertDialog(
          title: Text('Book: ${book.title}'),
          content: SizedBox(
            width: 700,
            height: constraints.maxHeight * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bookImage(book),
                      const SizedBox(width: 16),
                      Expanded(child: _bookDetailSection(book)),
                    ],
                  ),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Book Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<BookItem>>(
                    future: fetchBookCopiesByBookId(book.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        return const Center(child: Text('Không có bản sao nào.'));
                      }

                      final availableShelves = _shelves.where((s) => s.currentCount < s.capacityLimit).toList();

                      return Column(
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    final unassigned = items.where((i) => i.shelfId == 0);
                                    if (_isAllSelected(items)) {
                                      _selectedItemIds.clear();
                                    } else {
                                      _selectedItemIds.addAll(unassigned.map((e) => e.id.toString()));
                                    }
                                  });
                                },
                                child: Text(_isAllSelected(items) ? 'Bỏ chọn tất cả' : 'Chọn tất cả chưa gán'),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<int>(
                                hint: const Text('Chọn kệ'),
                                value: _selectedShelfId,
                                onChanged: (val) => setState(() => _selectedShelfId = val),
                                items: availableShelves.map((s) {
                                  final left = s.capacityLimit - s.currentCount;
                                  return DropdownMenuItem(value: s.id, child: Text('${s.name} (còn $left)'));
                                }).toList(),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                ),
                                onPressed: (_selectedShelfId != null && _selectedItemIds.isNotEmpty)
                                    ? () async {
                                  try {
                                    final ids = _selectedItemIds.toList(); // giữ nguyên là List<String>
                                    await updateShelfBulk(ids, _selectedShelfId!);

                                    // Update lại local sau khi update thành công
                                    final shelf = _shelves.firstWhere((s) => s.id == _selectedShelfId);
                                    shelf.currentCount += ids.length;
                                    await _logAction(
                                      actionType: 'UPDATE',
                                      targetId: widget.book.id,
                                      description: 'Gán ${ids.length} bản sao sách "${widget.book.title}" vào kệ ${shelf.name}',
                                    );
                                    setState(() => _selectedItemIds.clear());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Đã gán ${ids.length} bản sao vào ${shelf.name}')),
                                    );
                                  } catch (e) {
                                    debugPrint('❌ Error when bulk updating shelf: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi khi gán: $e')),
                                    );
                                  }
                                }
                                    : null,
                                child: const Text('GÁN ĐỒNG LOẠT'),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (ctx, index) {
                                final item = items[index];
                                final isSelected = _selectedItemIds.contains(item.id.toString());

                                return GestureDetector(
                                  onPanStart: (_) => setState(() => _dragSelecting = true),
                                  onPanEnd: (_) => setState(() => _dragSelecting = false),
                                  child: MouseRegion(
                                    onEnter: (_) {
                                      if (_dragSelecting && item.shelfId == 0 && mounted) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() => _selectedItemIds.add(item.id.toString()));
                                          }
                                        });
                                      }
                                    },
                                    child: Container(
                                      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                                      child: ListTile(
                                        title: Text('ID: ${item.id}'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Status: ${item.status}'),
                                            Text('Shelf: ${item.shelfId != 0 ? getShelfName(item.shelfId) : "Chưa gán"}'),
                                            Text('Created: ${DateFormat('yyyy-MM-dd').format(item.timeCreate)}'),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (checked) {
                                                setState(() {
                                                  checked == true
                                                      ? _selectedItemIds.add(item.id.toString())
                                                      : _selectedItemIds.remove(item.id.toString());
                                                });
                                              },
                                              activeColor: AppColors.primary,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                                              onPressed: () async {
                                                final result = await showDialog(
                                                  context: context,
                                                  builder: (_) => BookItemDialogUpdate(bookItem: item),
                                                );
                                                if (result == true) {
                                                  await _loadShelves(); // load lại capacity kệ
                                                  setState(() {});      // refresh danh sách item
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ĐÓNG', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
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
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<List<BookItem>> fetchBookCopiesByBookId(String bookId) async {
    final res = await http.get(Uri.parse('http://localhost:3003/api/bookcopies/by-book/$bookId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<BookItem>.from(data.map((e) => BookItem.fromJson(e)));
    } else {
      throw Exception('Failed to load book copies');
    }
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
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi tải danh sách kệ: $e');
    }
  }

  Future<void> updateShelfBulk(List<String> ids, int shelfId) async {
    final url = Uri.parse('http://localhost:3003/api/bookcopies/bulk-update-shelf');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'ids': ids,
        'shelf_id': shelfId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Bulk update shelf failed: ${response.body}');
    } else {
      debugPrint('✅ Bulk update shelf success: ${response.body}');
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
}
