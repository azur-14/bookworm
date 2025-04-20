class BorrowRequest {
  final String? id;
  final String userId;
  final String bookCopyId;
  final String status;
  final DateTime requestDate;
  final DateTime dueDate;

  BorrowRequest({
    this.id,
    required this.userId,
    required this.bookCopyId,
    this.status = 'pending',
    required this.requestDate,
    required this.dueDate, required String bookId,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'bookCopyId': bookCopyId,
    'status': status,
    'requestDate': requestDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
  };
}
