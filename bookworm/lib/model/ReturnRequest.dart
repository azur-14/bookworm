class ReturnRequest {
  final String id;
  final String borrowRequestId;
  String status;            // 'processing', 'completed', 'overdue'
  final DateTime returnDate;
  String? returnImageBase64;
  String? condition;

  ReturnRequest({
    required this.id,
    required this.borrowRequestId,
    this.status = 'processing',
    DateTime? returnDate,
    this.returnImageBase64,
    this.condition,
  }) : returnDate = returnDate ?? DateTime.now();

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] as String,
      borrowRequestId: json['borrow_request_id'] as String,
      status: json['status'] as String? ?? 'processing',
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'] as String)
          : null,
      returnImageBase64: json['return_image_base64'] as String?,
      condition: json['condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'borrow_request_id': borrowRequestId,
      'status': status,
      'return_date': returnDate.toIso8601String(),
      'return_image_base64': returnImageBase64,
      'condition': condition,
    };
  }
}
