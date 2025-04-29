import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/BookItem.dart';
import 'package:bookworm/model/Shelf.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'BookItemDialogUpdate.dart';

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

  final List<Shelf> _shelves = [
    Shelf(id: 1, name: 'Shelf A', description: '', capacityLimit: 5, currentCount: 2, timeCreate: DateTime.now()),
    Shelf(id: 2, name: 'Shelf B', description: '', capacityLimit: 4, currentCount: 4, timeCreate: DateTime.now()),
    Shelf(id: 3, name: 'Shelf C', description: '', capacityLimit: 6, currentCount: 3, timeCreate: DateTime.now()),
  ];

  Future<List<BookItem>> fetchItems() async {
    if (_cache.containsKey(widget.book.id)) return _cache[widget.book.id]!;
    await Future.delayed(const Duration(milliseconds: 300));
    final items = [
      BookItem(id: 1, bookId: widget.book.id, shelfId: null, status: 'available', damageImage: null, timeCreate: DateTime.now().subtract(const Duration(days: 10))),
      BookItem(id: 2, bookId: widget.book.id, shelfId: null, status: 'borrowed', damageImage: null, timeCreate: DateTime.now().subtract(const Duration(days: 5))),
    ];
    _cache[widget.book.id] = items;
    return items;
  }

  String getShelfName(int? shelfId) {
    final shelf = _shelves.firstWhere((s) => s.id == shelfId, orElse: () => Shelf(id: 0, name: 'Unknown', description: '', capacityLimit: 0, currentCount: 0, timeCreate: DateTime.now()));
    return shelf.name;
  }

  bool _isAllSelected(List<BookItem> items) =>
      _selectedItemIds.length == items.where((i) => i.shelfId == null).length;

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
                    future: fetchItems(),
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
                                    final unassigned = items.where((i) => i.shelfId == null);
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
                                  final shelf = _shelves.firstWhere((s) => s.id == _selectedShelfId);
                                  int count = 0;
                                  for (var id in _selectedItemIds) {
                                    if (shelf.currentCount >= shelf.capacityLimit) break;
                                    final item = items.firstWhere((i) => i.id.toString() == id);
                                    if (item.shelfId == null) {
                                      item.shelfId = shelf.id;
                                      await updateBookItemOnServer(item);
                                      shelf.currentCount++;
                                      count++;
                                    }
                                  }
                                  setState(() => _selectedItemIds.clear());
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gán $count bản sao vào ${shelf.name}')));
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
                                      if (_dragSelecting && item.shelfId == null && mounted) {
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
                                            Text('Shelf: ${item.shelfId != null ? getShelfName(item.shelfId) : "Chưa gán"}'),
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
                                                await showDialog(
                                                  context: context,
                                                  builder: (_) => BookItemDialogUpdate(bookItem: item),
                                                );
                                                setState(() {});
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

  Future<void> updateBookItemOnServer(BookItem item) async {
    await Future.delayed(const Duration(milliseconds: 200)); // giả lập API
  }
}
