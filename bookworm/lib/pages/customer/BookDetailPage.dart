import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:intl/intl.dart';

class BookDetailPage extends StatelessWidget {
  final Book book;
  final List<Category> categories;

  const BookDetailPage({
    Key? key,
    required this.book,
    required this.categories,
  }) : super(key: key);

  String _catName(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Unknown')).name;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('MMM dd, yyyy').format(book.timeCreate);
    final isAvailable = book.availableQuantity > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF594A47),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 300,
                child: book.image.isNotEmpty
                    ? Image.network(book.image, fit: BoxFit.cover)
                    : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, size: 60, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            AutoSizeText(
              book.title,
              maxLines: 2,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Metadata
            Text('Author: ${book.author}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Publisher: ${book.publisher}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Year: ${book.publishYear}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Category: ${_catName(book.categoryId)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Created: $created', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),

            // Availability & quantities
            Row(
              children: [
                Text(
                  isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'In stock: ${book.availableQuantity}/${book.totalQuantity}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if ((book.description ?? '').isNotEmpty) ...[
              const Text('Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(book.description!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
            ],

            // Borrow button
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_basket),
              label: AutoSizeText(
                isAvailable
                    ? 'Borrow (${book.availableQuantity})'
                    : 'Unavailable',
                maxLines: 1,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable ? const Color(0xFF7B4F3C) : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isAvailable
                  ? () {
                // TODO: xử lý mượn sách
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('You borrowed "${book.title}"')),
                );
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
