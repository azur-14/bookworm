import 'package:flutter/material.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import '../../pages/customer/BookDetailPage.dart';
import '../../pages/customer/BookSheft.dart';
import 'BookItem.dart';

class BookGallery extends StatelessWidget {
  final List<Book> books;
  final List<Category> categories;
  final bool gridView;

  const BookGallery({
    Key? key,
    required this.books,
    required this.categories,
    required this.gridView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('No books found'));
    }
    return gridView ? _buildGrid() : _buildList();
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = 180.0;
        final crossAxisCount = (width / itemWidth).floor().clamp(1, 6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.65,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              categories: categories,
              getCategoryName: (id) => categories
                  .firstWhere(
                    (c) => c.id == id,
                orElse: () => Category(id: '', name: 'Unknown'),
              )
                  .name,
            );
          },
        );
      },
    );
  }

  Widget _buildList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: SizedBox(
              width: 60,
              height: 90,
              child: BookImage(book: book, width: 60, height: 90),
            ),
            title: Text(
              book.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Text(
                  'by ${book.author}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${book.publishYear}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Text(
              book.availableQuantity > 0 ? 'Available' : 'Unavailable',
              style: TextStyle(
                color: book.availableQuantity > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailPage(book: book, categories: categories),
              ),
            ),
          ),
        );
      },
    );
  }
}
