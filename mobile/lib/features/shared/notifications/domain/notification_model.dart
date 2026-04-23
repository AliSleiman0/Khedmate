class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Notification type — e.g. `JOB_ACCEPTED`, `MAINTENANCE_REMINDER`,
  /// `VERIFICATION_APPROVED`. Empty string when server omits it.
  final String type;

  /// Raw server payload (mirrors FCM `data` map). Keys commonly seen:
  /// `jobId`, `categoryId`, `reminderId`, `disputeId`.
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
    required this.data,
  });

  String? get jobId => data['jobId']?.toString();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final Map<String, dynamic> parsed = rawData is Map<String, dynamic>
        ? rawData
        : const <String, dynamic>{};
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: json['type'] as String? ?? '',
      data: parsed,
    );
  }
}
