class BorrowRequest {
  final String? id;
  final String userId;
  final String bookCopyId;
  final String bookId;
  String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final DateTime requestDate;
  DateTime? receiveDate;
  DateTime? dueDate;
  DateTime? returnDate;

  // Cancellation & approval info
  final String? userCancelReason;
  String? librarianCancelReason;
  String? cancelledBy;
  DateTime? cancelledDate;

  String? approvedBy;
  DateTime? approvedDate;

  BorrowRequest({
    this.id,
    required this.userId,
    required this.bookCopyId,
    required this.bookId,
    this.status = 'pending',
    DateTime? requestDate,
    this.receiveDate,
    this.dueDate,
    this.returnDate,
    this.userCancelReason,
    this.librarianCancelReason,
    this.cancelledBy,
    this.cancelledDate,
    this.approvedBy,
    this.approvedDate,
  }) : requestDate = requestDate ?? DateTime.now();

  factory BorrowRequest.fromJson(Map<String, dynamic> json) {
    return BorrowRequest(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bookCopyId: json['book_copy_id']?.toString() ?? '',
      bookId: json['book_id'] as String,
      status: json['status'] as String? ?? 'pending',
      requestDate: DateTime.parse(json['request_date'] as String),
      receiveDate: json['receive_date'] != null
          ? DateTime.parse(json['receive_date'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'] as String)
          : null,
      userCancelReason: json['user_cancel_reason'] as String?,
      librarianCancelReason: json['librarian_cancel_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledDate: json['cancelled_date'] != null
          ? DateTime.parse(json['cancelled_date'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      approvedDate: json['approved_date'] != null
          ? DateTime.parse(json['approved_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'book_copy_id': bookCopyId,
    'book_id': bookId,
    'status': status,
    'request_date': requestDate.toIso8601String(),
    'receive_date': receiveDate?.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'return_date': returnDate?.toIso8601String(),
    'user_cancel_reason': userCancelReason,
    'librarian_cancel_reason': librarianCancelReason,
    'cancelled_by': cancelledBy,
    'cancelled_date': cancelledDate?.toIso8601String(),
    'approved_by': approvedBy,
    'approved_date': approvedDate?.toIso8601String(),
  };
}
