import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';

// ---------------------------------------------------------------------------
// Chat message model
// ---------------------------------------------------------------------------
class ChatMessage {
  final String id;
  final String jobId;
  final String senderId;
  final String senderType; // "customer" or "provider"
  final String text;
  final DateTime sentAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.senderType,
    required this.text,
    required this.sentAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] ?? '').toString(),
        jobId: (json['jobId'] ?? '').toString(),
        senderId: (json['senderId'] ?? '').toString(),
        senderType: json['senderType'] as String? ?? '',
        text: json['text'] as String? ?? '',
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String).toLocal()
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// Chat message list widget
// ---------------------------------------------------------------------------
class ChatMessageList extends ConsumerWidget {
  final String selfSenderType;
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const ChatMessageList({
    super.key,
    required this.selfSenderType,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);

    if (messages.isEmpty) {
      return Center(
        child: Text(
          s.chatNoMessages,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isSelf = msg.senderType == selfSenderType;

        final showDateSeparator = index == 0 ||
            !_isSameDay(messages[index - 1].sentAt, msg.sentAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateSeparator) _DateSeparator(date: msg.sentAt, s: s),
            _MessageBubble(message: msg, isSelf: isSelf),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelf;

  const _MessageBubble({required this.message, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
                isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelf
                      ? AppColors.brandBlue
                      : const Color(0xFFECECEC),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSelf ? 16 : 4),
                    bottomRight: Radius.circular(isSelf ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: isSelf ? Colors.white : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(message.sentAt),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'ص' : 'م';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $period';
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final S s;

  const _DateSeparator({required this.date, required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDate(date),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    if (dateOnly == today) return s.chatToday;
    if (dateOnly == yesterday) return s.chatYesterday;

    if (s.isAr) {
      const arMonths = [
        '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${dt.day} ${arMonths[dt.month]} ${dt.year}';
    } else {
      const enMonths = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${enMonths[dt.month]} ${dt.day}, ${dt.year}';
    }
  }
}
