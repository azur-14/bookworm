// lib/utils/combined_status.dart
import 'package:bookworm/model/BorowRequest.dart';
import 'package:bookworm/model/ReturnRequest.dart';

/// Tìm ReturnRequest tương ứng (nếu có)
ReturnRequest? findReturn(BorrowRequest b, List<ReturnRequest> allReturns) {
  try {
    return allReturns.firstWhere((r) => r.borrowRequestId == b.id);
  } catch (_) {
    return null;
  }
}

/// Gom status raw của Borrow + Return thành label hiển thị
String getCombinedStatus(BorrowRequest r, List<ReturnRequest> allReturns) {
  final ret = findReturn(r, allReturns);
  if (r.status == 'pending') return 'Chờ duyệt';
  if (r.status == 'rejected') return 'Từ chối';
  if (r.status == 'approved' && ret == null) return 'Chờ nhận';
  if (ret != null && ret.status == 'processing') return 'Đang mượn';
  if (ret != null && ret.status == 'overdue') return 'Trả quá hạn';
  if (ret != null && ret.status == 'completed') {
    if (ret.condition != null && ret.condition!.isNotEmpty) return 'Hư hao';
    if (r.dueDate != null && ret.returnDate.isAfter(r.dueDate!)) {
      return 'Trả quá hạn';
    }
    return 'Đã trả';
  }
  return 'Không rõ';
}
