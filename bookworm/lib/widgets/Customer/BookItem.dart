import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/Book.dart';
import '../../model/Category.dart';
import '../../pages/customer/BookDetailPage.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final List<Category> categories;
  final String Function(String) getCategoryName;

  const BookCard({
    Key? key,
    required this.book,
    required this.categories,
    required this.getCategoryName,
  }) : super(key: key);

  bool hasAvailableCopy(int available) => available > 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Book: ${book.title}, by ${book.author}',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookDetailPage(book: book, categories: categories),
              ),
            ),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: BookImage(book: book),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      book.title,
                      maxLines: 2,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${book.author}',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getCategoryName(book.categoryId),
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${book.publishYear}',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasAvailableCopy(book.availableQuantity)
                          ? 'Available'
                          : 'Unavailable',
                      style: TextStyle(
                        color: hasAvailableCopy(book.availableQuantity)
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookImage extends StatelessWidget {
  final Book book;
  final double width;
  final double height;

  const BookImage({
    Key? key,
    required this.book,
    this.width = double.infinity,
    this.height = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (book.image.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.book, size: 30, color: Colors.grey),
      );
    }
    try {
      final bytes = base64Decode(book.image);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, error, __) =>
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(Icons.book, size: 30, color: Colors.grey),
            ),
      );
    } catch (_) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.book, size: 30, color: Colors.grey),
      );
    }
  }
}
