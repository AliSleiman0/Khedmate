import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/signalr_service.dart';
import '../../../shared/widgets/chat/chat_input_bar.dart';
import '../../../shared/widgets/chat/chat_message_list.dart';
import 'chat_provider.dart';

class ProviderChatScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String otherPartyName; // customer's first name

  const ProviderChatScreen({
    super.key,
    required this.jobId,
    required this.otherPartyName,
  });

  @override
  ConsumerState<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends ConsumerState<ProviderChatScreen> {
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
    final asyncChat = ref.watch(chatNotifierProvider(widget.jobId));

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
                        : s.chatCustomer,
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
                      ref.refresh(chatNotifierProvider(widget.jobId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue),
                  child: Text(s.retry,
                      style: const TextStyle(
                          fontFamily: 'Cairo', color: Colors.white)),
                ),
              ],
            ),
          ),
          data: (chatState) => _ChatBody(
            jobId: widget.jobId,
            chatState: chatState,
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
  final ScrollController scrollController;
  final VoidCallback onScrollToBottom;

  const _ChatBody({
    required this.jobId,
    required this.chatState,
    required this.scrollController,
    required this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (chatState.isLoadingMore)
          const LinearProgressIndicator(
            color: AppColors.brandBlue,
            backgroundColor: AppColors.surface,
          ),
        Expanded(
          child: ChatMessageList(
            selfSenderType: 'provider',
            messages: chatState.messages,
            scrollController: scrollController,
          ),
        ),
        ChatInputBar(
          isSending: chatState.isSending,
          onSend: (text) {
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
