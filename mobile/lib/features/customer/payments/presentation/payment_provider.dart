class PaymentSummary {
  final String transactionId;
  final String status;
  final double amount;
  final double commissionAmount;
  final double netToProvider;

  const PaymentSummary({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.commissionAmount,
    required this.netToProvider,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
        transactionId: json['id'] as String,
        status: json['status'] as String,
        amount: (json['grossAmount'] as num).toDouble(),
        commissionAmount: (json['commissionAmount'] as num).toDouble(),
        netToProvider: (json['netAmount'] as num).toDouble(),
      );
}
