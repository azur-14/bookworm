// lib/pages/borrow_return_review/widgets/dialogs.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/ReturnRequest.dart';
import 'package:bookworm/model/RequestStatusHistory.dart';
import 'package:bookworm/model/Bill.dart';
import 'package:bookworm/model/Book.dart';
import 'package:http/http.dart' as http;

import '../../../model/BorowRequest.dart';

Widget buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

/// 1) Hiển thị lịch sử thay đổi trạng thái của 1 request
Future<void> showHistoryDialog(BuildContext context, String requestId) async {
  try {
    final res = await http.get(
      Uri.parse('http://localhost:3002/api/requestStatusHistory/$requestId'),
    );
    final List<RequestStatusHistory> histories = res.statusCode == 200
        ? (json.decode(res.body) as List)
        .map((e) => RequestStatusHistory.fromJson(e))
        .toList()
        : [];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Lịch sử thay đổi ($requestId)', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: histories.isEmpty
              ? const Text('Chưa có lịch sử thay đổi.')
              : ListView.builder(
            itemCount: histories.length,
            shrinkWrap: true,
            itemBuilder: (_, i) {
              final h = histories[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔁 ${h.oldStatus} → ${h.newStatus}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('🕒 ${DateFormat('yyyy-MM-dd HH:mm').format(h.changeTime)}'),
                      Text('👤 ${h.changedBy}'),
                      if (h.reason.isNotEmpty) Text('📄 Lý do: ${h.reason}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không tải được lịch sử: $e')),
    );
  }
}

/// 2) Hiển thị chi tiết phiếu mượn/trả
Future<void> showBorrowReturnInfoDialog(
    BuildContext context, BorrowRequest borrow, ReturnRequest? ret) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Chi tiết yêu cầu ${borrow.id}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📘 Thông tin mượn',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    buildInfoRow('User', borrow.userEmail ?? borrow.userId),
                    buildInfoRow('Book ID', borrow.bookId),
                    buildInfoRow('BookCopy ID', borrow.bookCopyId),
                    buildInfoRow('Requested',
                        DateFormat('yyyy-MM-dd HH:mm').format(borrow.requestDate)),
                    if (borrow.receiveDate != null)
                      buildInfoRow('Received',
                          DateFormat('yyyy-MM-dd HH:mm').format(borrow.receiveDate!)),
                    buildInfoRow('Due',
                        DateFormat('yyyy-MM-dd HH:mm').format(borrow.dueDate!)),
                  ],
                ),
              ),
            ),
            if (ret != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📦 Thông tin trả',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      buildInfoRow('Return ID', ret.id),
                      if (ret.returnDate != null)
                        buildInfoRow('Returned',
                            DateFormat('yyyy-MM-dd HH:mm').format(ret.returnDate!))
                      else
                        const Text('Returned: (đang chờ hoàn trả)',
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      if (ret.condition != null)
                        buildInfoRow('Tình trạng', ret.condition!),
                      if (ret.returnImageBase64 != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(ret.returnImageBase64!),
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// 3) Dialog hoàn thành trả sách, tính phí và tạo hóa đơn
Future<void> showCompleteReturnDialog(
    BuildContext context, {
      required ReturnRequest retReq,
      required BorrowRequest borrow,
      required Book book,
      required int overdueFeePerDay,
    }) async {
  final picker = ImagePicker();
  String selectedState = retReq.condition ?? 'Nguyên vẹn';
  String? imgBase64 = retReq.returnImageBase64;
  String amountStr = '';

  final daysLate =
  DateTime.now().difference(borrow.dueDate!).inDays.clamp(0, 999).toInt();
  final overdueFee = daysLate * overdueFeePerDay;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (_, setSt) {
      double damagePct;
      switch (selectedState) {
        case 'Hư hao nhẹ':
          damagePct = 10;
          break;
        case 'Hư tổn đáng kể':
          damagePct = 50;
          break;
        case 'Mất':
          damagePct = 100;
          break;
        default:
          damagePct = 0;
      }
      final damageFee = (damagePct / 100) * book.price;
      final totalFee = overdueFee + damageFee;

      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment_turned_in, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Hoàn thành trả ${retReq.id}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedState,
                decoration: const InputDecoration(labelText: 'Tình trạng sách'),
                items: ['Nguyên vẹn', 'Hư hao nhẹ', 'Hư tổn đáng kể', 'Mất']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setSt(() => selectedState = v ?? selectedState),
              ),
              const SizedBox(height: 8),
              if (selectedState != 'Nguyên vẹn') ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Chọn ảnh minh họa'),
                  onPressed: () async {
                    final img =
                    await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      final bytes = await img.readAsBytes();
                      setSt(() => imgBase64 = base64Encode(bytes));
                    }
                  },
                ),
                if (imgBase64 != null) ...[
                  const SizedBox(height: 8),
                  Image.memory(base64Decode(imgBase64!), height: 120),
                ],
                const Divider(),
                Text('📅 Trễ: $daysLate ngày → ${NumberFormat.decimalPattern().format(overdueFee)}₫'),
                Text('🔧 Hư hại: ${damagePct.toInt()}% của ${NumberFormat.decimalPattern().format(book.price)}₫ → ${NumberFormat.decimalPattern().format(damageFee)}₫'),
                const Divider(),
                Text('💰 Tổng cộng: ${NumberFormat.decimalPattern().format(totalFee)}₫'),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Số tiền khách đưa (₫)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setSt(() => amountStr = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final paid = selectedState == 'Nguyên vẹn'
                  ? 0.0
                  : double.tryParse(amountStr) ?? totalFee;
              final change = (paid - totalFee) < 0 ? 0.0 : (paid - totalFee);

              final bill = Bill(
                id: 'bill_${retReq.borrowRequestId}_${DateTime.now().millisecondsSinceEpoch}',
                requestId: retReq.borrowRequestId,
                type: 'book',
                overdueDays: daysLate,
                overdueFee: overdueFee,
                damageFee: damageFee,
                totalFee: totalFee,
                amountReceived: paid,
                changeGiven: change,
                date: DateTime.now(),
              );

              // TODO: Gọi API cập nhật trạng thái, tạo returnRequest, lưu hóa đơn...

              Navigator.pop(ctx);

              if (selectedState != 'Nguyên vẹn') {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Hóa đơn thanh toán'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInfoRow('Borrow ID', retReq.borrowRequestId),
                        buildInfoRow('Phí quá hạn', '${NumberFormat.decimalPattern().format(overdueFee)}₫'),
                        buildInfoRow('Phí hư hại', '${NumberFormat.decimalPattern().format(damageFee)}₫'),
                        const Divider(),
                        buildInfoRow('Tổng cộng', '${NumberFormat.decimalPattern().format(totalFee)}₫'),
                        buildInfoRow('Khách đưa', '${NumberFormat.decimalPattern().format(paid)}₫'),
                        buildInfoRow('Trả lại', '${NumberFormat.decimalPattern().format(change)}₫'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      );
    }),
  );
}
