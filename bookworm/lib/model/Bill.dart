class Bill {
  final String id;
  final String borrowRequestId;
  final int overdueDays;
  final int overdueFee;    // VND
  final int damageFee;     // VND
  final int totalFee;      // VND
  final int amountReceived;// VND khách đưa
  final int changeGiven;   // VND trả lại
  final DateTime date;     // ngày lập hóa đơn

  Bill({
    required this.id,
    required this.borrowRequestId,
    required this.overdueDays,
    required this.overdueFee,
    required this.damageFee,
    required this.totalFee,
    required this.amountReceived,
    required this.changeGiven,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'],
    borrowRequestId: json['borrow_request_id'],
    overdueDays: json['overdue_days'],
    overdueFee: json['overdue_fee'],
    damageFee: json['damage_fee'],
    totalFee: json['total_fee'],
    amountReceived: json['amount_received'],
    changeGiven: json['change_given'],
    date: DateTime.parse(json['date']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'borrow_request_id': borrowRequestId,
    'overdue_days': overdueDays,
    'overdue_fee': overdueFee,
    'damage_fee': damageFee,
    'total_fee': totalFee,
    'amount_received': amountReceived,
    'change_given': changeGiven,
    'date': date.toIso8601String(),
  };
}
