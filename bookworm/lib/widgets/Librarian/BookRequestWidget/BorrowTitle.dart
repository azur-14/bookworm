// lib/pages/borrow_return_review/widgets/BorrowTile.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookworm/theme/AppColor.dart';
import '../../../model/BorowRequest.dart';
import '../../../model/ReturnRequest.dart';
import '../../../model/Book.dart';
import 'Dialog.dart';

class BorrowTile extends StatelessWidget {
  final BorrowRequest request;
  final ReturnRequest? retRequest;
  final Book? book;
  final int overdueFeePerDay;
  final String? userId;

  const BorrowTile({
    Key? key,
    required this.request,
    required this.retRequest,
    required this.book,
    required this.overdueFeePerDay,
    required this.userId,
  }) : super(key: key);

  String get _label {
    if (request.status == 'pending') return 'Chờ duyệt';
    if (request.status == 'rejected') return 'Từ chối';
    if (request.status == 'approved' && retRequest == null) return 'Chờ nhận';
    if ((request.status == 'received' && retRequest == null) ||
        (request.status == 'received' && retRequest?.status == 'processing')) {
      return 'Đang mượn';
    }
    if (retRequest?.status == 'completed') return 'Đã trả';
    return 'Không rõ';
  }

  Color get _color {
    switch (_label) {
      case 'Chờ duyệt':
        return Colors.orange;
      case 'Chờ nhận':
      case 'Đang mượn':
        return Colors.blueAccent;
      case 'Hư hao':
      case 'Từ chối':
        return Colors.redAccent;
      case 'Đã trả':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (_label) {
      case 'Chờ duyệt':
        return Icons.hourglass_top;
      case 'Chờ nhận':
        return Icons.inventory_2;
      case 'Đang mượn':
        return Icons.book;
      case 'Hư hao':
        return Icons.report_problem;
      case 'Đã trả':
        return Icons.assignment_turned_in;
      case 'Từ chối':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildActions(BuildContext context) {
    final now = DateTime.now();
    final due = request.dueDate;
    final hasDue = (due != null);
    final isPast = hasDue && now.isAfter(due!);

    switch (_label) {
      case 'Chờ duyệt':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _updateStatus('approved'),
              child: const Text('Approve', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF6D4C41), // nâu đậm
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _updateStatus('rejected'),
              child: const Text('Reject', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red, // be sáng
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        );
      case 'Chờ nhận':
        return SizedBox(
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isPast) ...[
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(height: 2),
                const Text(
                  'Quá ngày nhận',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ],
              TextButton(
                onPressed: () => _updateStatus(isPast ? 'cancelled' : 'received'),
                child: Text(
                  isPast ? 'Hủy' : 'Xác nhận',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );

      case 'Đang mượn':
        final ret = retRequest;
        final overdue = hasDue && now.isAfter(due!);
        if (overdue && ret == null) {
          return TextButton(
            onPressed: () => _sendOverdueEmail(),
            child: const Text('Nhắc quá hạn', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(minimumSize: const Size(0, 24)),
          );
        }
        if (ret != null && ret.status == 'processing') {
          return TextButton(
            onPressed: () => _showCompleteReturnDialog(context),
            child: const Text('Hoàn thành', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(minimumSize: const Size(0, 24)),
          );
        }
        return const SizedBox.shrink();

      case 'Hư hao':
        return TextButton(
          onPressed: () => _showCompleteReturnDialog(context),
          child: const Text('Xử lý', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(minimumSize: const Size(0, 24)),
        );

      default:
      // 'Đã trả', 'Từ chối', v.v.
        return const SizedBox.shrink();
    }
  }


  Future<void> _updateStatus(String newStatus) async {
    final url =
        'http://localhost:3002/api/borrowRequest/${request.id}/status';
    await http.put(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'newStatus': newStatus, 'changedBy': userId}));
    // TODO: gọi lại setState ở parent để reload
  }

  Future<void> _sendOverdueEmail() async {
    final url =
        'http://localhost:3002/api/borrowRequest/send-overdue-email/${request.id}';
    await http.post(Uri.parse(url));
    // TODO: show snackBar
  }

  Future<void> _showCompleteReturnDialog(BuildContext context) async {
    if (retRequest == null || book == null) return;
    await showCompleteReturnDialog(
      context,
      retReq: retRequest!,
      borrow: request,
      book: book!,
      overdueFeePerDay: overdueFeePerDay,
    );
    // TODO: gọi reload dữ liệu ở parent
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => showBorrowReturnInfoDialog(
            context, request, retRequest),
        leading: CircleAvatar(
          backgroundColor: _color,
          child: Icon(_icon, color: Colors.white),
        ),
        title: Text(request.bookTitle ?? request.bookId),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${request.userEmail ?? request.userId}'),
            Text(
                'Requested: ${DateFormat('yyyy-MM-dd').format(request.requestDate)}'),
          ],
        ),
        trailing: _buildActions(context),
      ),
    );
  }
}
