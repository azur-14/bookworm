class Bill {
  final String id;
  final String requestId;
  final String type;
  final int? overdueDays;
  final int? overdueFee; // VND
  final double? damageFee; // VND
  final double totalFee; // VND
  final double amountReceived; // VND khách đưa
  final double changeGiven; // VND trả lại
  final DateTime date; // ngày lập hóa đơn

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

  factory Bill.fromJson(Map<String, dynamic> json) =>
      Bill(
        id: json['id'],
        requestId: json['borrowRequestId'],
        // thay json['request_id']
        type: json['type'],
        overdueDays: json['overdueDays'] as int?,
        overdueFee: json['overdueFee'] as int?,
        damageFee: (json['damageFee'] as num?)?.toDouble(),
        totalFee: (json['totalFee'] as num).toDouble(),
        amountReceived: (json['amountReceived'] as num).toDouble(),
        changeGiven: (json['changeGiven'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'borrowRequestId': requestId, // thay request_id
        'type': type,
        'overdueDays': overdueDays,
        'overdueFee': overdueFee,
        'damageFee': damageFee,
        'totalFee': totalFee,
        'amountReceived': amountReceived,
        'changeGiven': changeGiven,
        'date': date.toIso8601String(),
      };
}