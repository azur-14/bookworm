class Bill {
  final String id;
  final String requestId;
  final String type;
  final int? overdueDays;
  final int? overdueFee;    // VND
  final double? damageFee;     // VND
  final double totalFee;      // VND
  final double amountReceived;// VND khách đưa
  final double changeGiven;   // VND trả lại
  final DateTime date;     // ngày lập hóa đơn

  Bill({
    required this.id,
    required this.requestId,
    required this.type,
    this.overdueDays,
    this.overdueFee,
    this.damageFee,
    required this.totalFee,
    required this.amountReceived,
    required this.changeGiven,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'],
    requestId: json['request_id'],
    type: json['type'],
    overdueDays: (json['overdue_days'] as num?)?.toInt() ?? 0,
    overdueFee: (json['overdue_fee'] as num?)?.toInt() ?? 0,
    damageFee: (json['damage_fee'] as num?)?.toDouble() ?? 0.0,
    totalFee: json['total_fee'],
    amountReceived: json['amount_received'],
    changeGiven: json['change_given'],
    date: DateTime.parse(json['date']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'borrow_request_id': requestId,
    'overdue_days': overdueDays,
    'overdue_fee': overdueFee,
    'damage_fee': damageFee,
    'total_fee': totalFee,
    'amount_received': amountReceived,
    'change_given': changeGiven,
    'date': date.toIso8601String(),
  };
}
