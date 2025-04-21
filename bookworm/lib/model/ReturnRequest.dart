class ReturnRequest {
  final String id;
  final String borrowRequestId;
  final DateTime returnDate;
  final String status;        // 'processing', 'completed', 'overdue'
  final String returnImage;   // URL hoặc base64

  ReturnRequest({
    required this.id,
    required this.borrowRequestId,
    required this.returnDate,
    this.status = 'processing',
    this.returnImage = '',
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] as String,
      borrowRequestId: json['borrow_request_id'] as String,
      returnDate: DateTime.parse(json['return_date'] as String),
      status: json['status'] as String? ?? 'processing',
      returnImage: json['return_image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'borrow_request_id': borrowRequestId,
      'return_date': returnDate.toIso8601String(),
      'status': status,
      'return_image': returnImage,
    };
  }
}
