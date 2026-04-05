class ReferralInfo {
  final String code;
  final String shareUrl;
  final double creditBalance;
  final String currency;
  final int referralsCompleted;

  const ReferralInfo({
    required this.code,
    required this.shareUrl,
    required this.creditBalance,
    required this.currency,
    required this.referralsCompleted,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
        code: json['code'] as String? ?? '',
        shareUrl: json['shareUrl'] as String? ?? '',
        creditBalance: (json['creditBalance'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'SAR',
        referralsCompleted: (json['referralsCompleted'] as num?)?.toInt() ?? 0,
      );
}
