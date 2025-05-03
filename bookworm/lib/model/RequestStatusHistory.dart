class RequestStatusHistory {
  final String requestId;
  final String requestType;  // 'borrow', 'room', 'return'
  final String oldStatus;
  final String newStatus;
  final DateTime changeTime;
  final String changedBy;    // user or librarian ID
  final String reason;

  RequestStatusHistory({
    required this.requestId,
    required this.requestType,
    required this.oldStatus,
    required this.newStatus,
    DateTime? changeTime,
    required this.changedBy,
    this.reason = '',
  }) : changeTime = changeTime ?? DateTime.now();

  factory RequestStatusHistory.fromJson(Map<String, dynamic> json) {
    return RequestStatusHistory(
      requestId: json['requestId'] as String,
      requestType: json['requestType'] as String,
      oldStatus: json['oldStatus'] as String,
      newStatus: json['newStatus'] as String,
      changeTime: DateTime.parse(json['changeTime'] as String),
      changedBy: json['changedBy'] as String,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'requestType': requestType,
    'oldStatus': oldStatus,
    'newStatus': newStatus,
    'changeTime': changeTime.toIso8601String(),
    'changedBy': changedBy,
    'reason': reason,
  };
}
