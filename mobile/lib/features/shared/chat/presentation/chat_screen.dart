import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import 'chat_provider.dart';

const _tag = 'ChatScreen';

/// Unified chat screen used by both roles. The sender bubble alignment is
/// determined by the current `roleProvider` value.
class ChatScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String otherPartyName;

  const ChatScreen({
    super.key,
    required this.jobId,
    this.otherPartyName = '',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ensureSignalR();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _ensureSignalR() async {
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 50) {
      log.d(_tag, 'load prev page tap', data: {'jobId': widget.jobId});
      ref.read(chatNotifierProvider(widget.jobId).notifier).loadPreviousPage();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final role = ref.watch(roleProvider) ?? UserRole.customer;
    final selfSenderType =
        role == UserRole.provider ? 'provider' : 'customer';
    final asyncChat = ref.watch(chatNotifierProvider(widget.jobId));

    final fallbackOtherPartyLabel =
        role == UserRole.provider ? s.chatCustomer : s.chatProvider;

    ref.listen(chatNotifierProvider(widget.jobId), (_, next) {
      if (next.valueOrNull != null) _scrollToBottom();
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          leading: const AppBackButton(),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPartyName.isNotEmpty
                        ? widget.otherPartyName
                        : fallbackOtherPartyLabel,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    s.chatTitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: asyncChat.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandBlue),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text(
                  s.chatLoadError,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(chatNotifierProvider(widget.jobId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue),
                  child: Text(
                    s.retry,
                    style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          data: (chatState) => _ChatBody(
            jobId: widget.jobId,
            chatState: chatState,
            selfSenderType: selfSenderType,
            scrollController: _scrollController,
            onScrollToBottom: _scrollToBottom,
          ),
        ),
      ),
    );
  }
}

class _ChatBody extends ConsumerWidget {
  final String jobId;
  final ChatState chatState;
  final String selfSenderType;
  final ScrollController scrollController;
  final VoidCallback onScrollToBottom;

  const _ChatBody({
    required this.jobId,
    required this.chatState,
    required this.selfSenderType,
    required this.scrollController,
    required this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);

    if (chatState.errorMessage == 'SEND_FAILED') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.chatSendError,
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      });
    }

    return Column(
      children: [
        if (chatState.isLoadingMore)
          const LinearProgressIndicator(
            color: AppColors.brandBlue,
            backgroundColor: AppColors.surface,
          ),
        Expanded(
          child: ChatMessageList(
            selfSenderType: selfSenderType,
            messages: chatState.messages,
            scrollController: scrollController,
          ),
        ),
        ChatInputBar(
          isSending: chatState.isSending,
          onSend: (text) {
            log.d(_tag, 'send button tap',
                data: {'jobId': jobId, 'len': text.length});
            ref
                .read(chatNotifierProvider(jobId).notifier)
                .sendMessage(text)
                .then((_) => onScrollToBottom());
          },
        ),
      ],
    );
  }
}
