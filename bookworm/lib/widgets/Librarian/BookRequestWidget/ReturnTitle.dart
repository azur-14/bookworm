// lib/pages/borrow_return_review/widgets/ReturnTile.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/BorowRequest.dart';
import '../../../model/ReturnRequest.dart';
import '../../../model/Book.dart';
import 'Dialog.dart';

class ReturnTile extends StatelessWidget {
  final ReturnRequest request;
  final BorrowRequest? borrow;
  final Book? book;
  final int overdueFeePerDay;
  final String? userId;

  const ReturnTile({
    Key? key,
    required this.request,
    this.borrow,
    this.book,
    required this.overdueFeePerDay,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = 'Đã trả';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        onTap: () {
          if (borrow != null) {
            showBorrowReturnInfoDialog(context, borrow!, request);
          }
        },
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(Icons.assignment_turned_in, color: Colors.white),
        ),
        title: Text(book?.title ?? 'Return ${request.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${borrow?.userEmail ?? borrow?.userId ?? ''}'),
            if (request.returnDate != null)
              Text(
                'Returned: ${DateFormat('yyyy-MM-dd').format(request.returnDate!)}',
              ),
            if (request.condition != null)
              Text('Condition: ${request.condition}'),
          ],
        ),
        trailing: Text(label, style: const TextStyle(color: Colors.green)),
      ),
    );
  }
}
