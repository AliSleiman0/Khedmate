class SubscriptionInfo {
  final String plan; // 'PowerProvider'
  final String status; // 'Active' | 'PastDue' | 'Cancelled'
  final double monthlyFee;
  final double commissionRate;
  final DateTime currentPeriodEnd;
  final bool cancelsAtPeriodEnd;
  final String currency;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    required this.monthlyFee,
    required this.commissionRate,
    required this.currentPeriodEnd,
    required this.cancelsAtPeriodEnd,
    required this.currency,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String? ?? 'PowerProvider',
      status: json['status'] as String? ?? 'Active',
      monthlyFee: (json['monthlyFee'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 10.0,
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd'] as String),
      cancelsAtPeriodEnd: json['cancelsAtPeriodEnd'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'SAR',
    );
  }
}
