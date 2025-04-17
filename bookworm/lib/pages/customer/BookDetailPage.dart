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
        title: Text('Book Details'),
        backgroundColor: const Color(0xFF594A47),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: thumbnail + basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail nhỏ
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 150,
                    child: book.image.isNotEmpty
                        ? Image.network(book.image, fit: BoxFit.cover)
                        : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 40, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title + author + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        book.title,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('by ${book.author}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '${_catName(book.categoryId)} · ${book.publishYear}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text('Created: $created', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stock & availability
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable ? 'In Stock' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Text(
                  '${book.availableQuantity}/${book.totalQuantity}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            if ((book.description ?? '').isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(book.description!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
            ],

            // Borrow button đưa xuống cuối
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_basket),
              label: Text(
                isAvailable ? 'Borrow (${book.availableQuantity})' : 'Unavailable',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable ? const Color(0xFF7B4F3C) : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isAvailable
                  ? () {
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
