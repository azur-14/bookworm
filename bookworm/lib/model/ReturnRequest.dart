// lib/model/ReturnRequest.dart

class ReturnRequest {
  final String id;
  final String borrowRequestId;
  String status;            // 'processing', 'completed', 'overdue'
  DateTime? returnDate;
  String? returnImageBase64;
  String? condition;

  ReturnRequest({
    required this.id,
    required this.borrowRequestId,
    this.status = 'processing',
    this.returnDate,
    this.returnImageBase64,
    this.condition,
  });

  /// Constructor trả về object “rỗng” khi không tìm thấy
  factory ReturnRequest.empty() => ReturnRequest(
    id: '',
    borrowRequestId: '',
    status: '',
    returnDate: null,
    returnImageBase64: null,
    condition: null,
  );

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'borrow_request_id': borrowRequestId,
    'status': status,
    'return_date': returnDate?.toIso8601String(),
    'return_image_base64': returnImageBase64,
    'condition': condition,
  };
}
