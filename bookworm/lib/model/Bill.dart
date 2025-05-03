class Bill {
  final String id;
  final String borrowRequestId;
  final int overdueDays;
  final int overdueFee;       // VND
  final int damagePercentage; // % sách hư hại
  final int damageFee;        // VND
  final int totalFee;         // VND
  final int amountReceived;   // VND khách đưa
  final int changeGiven;      // VND trả lại
  final DateTime date;        // ngày lập hóa đơn

  Bill({
    required this.id,
    required this.borrowRequestId,
    required this.overdueDays,
    required this.overdueFee,
    required this.damagePercentage,
    required this.damageFee,
    required this.totalFee,
    required this.amountReceived,
    required this.changeGiven,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}
