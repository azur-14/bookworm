class BorrowRequest {
  final String? id;
  final String userId;
  final String bookCopyId;
  final String status;
  final DateTime requestDate;
  final DateTime dueDate;
  final String bookId; // thêm dòng này nếu muốn lấy bookId

  BorrowRequest({
    this.id,
    required this.userId,
    required this.bookCopyId,
    this.status = 'pending',
    required this.requestDate,
    required this.dueDate,
    required this.bookId,
  });

  factory BorrowRequest.fromJson(Map<String, dynamic> json) {
    return BorrowRequest(
      id: json['id'],
      userId: json['user_id'],
      bookCopyId: json['book_copy_id'].toString(), // có thể là int => ép thành String
      status: json['status'] ?? 'pending',
      requestDate: DateTime.parse(json['request_date']),
      dueDate: DateTime.parse(json['due_date']),
      bookId: json['book_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'book_copy_id': bookCopyId,
    'book_id': bookId,
    'status': status,
    'request_date': requestDate.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
  };
}
