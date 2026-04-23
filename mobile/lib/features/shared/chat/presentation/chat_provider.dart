import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/signalr_service.dart';
import '../data/chat_repository.dart';
import '../widgets/chat_message_list.dart';

class ChatState {
  final List<ChatMessage> messages;
  final int totalCount;
  final int currentPage;
  final bool isSending;
  final bool isLoadingMore;
  final String? errorMessage;

  const ChatState({
    required this.messages,
    required this.totalCount,
    required this.currentPage,
    this.isSending = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => messages.length < totalCount;

  ChatState copyWith({
    List<ChatMessage>? messages,
    int? totalCount,
    int? currentPage,
    bool? isSending,
    bool? isLoadingMore,
    String? errorMessage,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        totalCount: totalCount ?? this.totalCount,
        currentPage: currentPage ?? this.currentPage,
        isSending: isSending ?? this.isSending,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: errorMessage,
      );
}

class ChatNotifier extends FamilyAsyncNotifier<ChatState, String> {
  static const _pageSize = 50;

  @override
  Future<ChatState> build(String arg) async {
    final jobId = arg;
    final repo = ref.read(chatRepositoryProvider);

    final body = await repo.getMessages(jobId, 1, _pageSize);
    final dataMap = body['data'] as Map<String, dynamic>;
    final msgList = (dataMap['messages'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (dataMap['totalCount'] as int?) ?? msgList.length;

    try {
      await repo.markAsRead(jobId);
    } catch (_) {}

    _subscribeToMessages(jobId);

    return ChatState(
      messages: msgList,
      totalCount: total,
      currentPage: 1,
    );
  }

  void _subscribeToMessages(String jobId) {
    ref.read(signalRServiceProvider).on('NewChatMessage', (args) {
      final data = args?[0] as Map<String, dynamic>?;
      if (data == null) return;
      if (data['jobId'].toString() != jobId) return;

      final message = ChatMessage.fromJson(data);
      final current = state.valueOrNull;
      if (current == null) return;

      state = AsyncData(current.copyWith(
        messages: [...current.messages, message],
        totalCount: current.totalCount + 1,
      ));

      ref.read(chatRepositoryProvider).markAsRead(jobId).ignore();
    });
  }

  Future<void> sendMessage(String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSending: true));
    try {
      await ref.read(chatRepositoryProvider).sendMessage(arg, text);
      await _reloadLastPage();
    } catch (e) {
      state = AsyncData(
        current.copyWith(isSending: false, errorMessage: 'SEND_FAILED'),
      );
      return;
    }

    state = AsyncData(state.valueOrNull!.copyWith(isSending: false));
  }

  Future<void> _reloadLastPage() async {
    final body = await ref
        .read(chatRepositoryProvider)
        .getMessages(arg, 1, _pageSize);
    final dataMap = body['data'] as Map<String, dynamic>;
    final msgList = (dataMap['messages'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (dataMap['totalCount'] as int?) ?? msgList.length;

    state = AsyncData(ChatState(
      messages: msgList,
      totalCount: total,
      currentPage: 1,
      isSending: false,
    ));
  }

  Future<void> loadPreviousPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final body = await ref
          .read(chatRepositoryProvider)
          .getMessages(arg, nextPage, _pageSize);

      final dataMap = body['data'] as Map<String, dynamic>;
      final older = (dataMap['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (dataMap['totalCount'] as int?) ?? current.totalCount;

      state = AsyncData(current.copyWith(
        messages: [...older, ...current.messages],
        totalCount: total,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> markRead() async {
    try {
      await ref.read(chatRepositoryProvider).markAsRead(arg);
    } catch (_) {}
  }
}

final chatNotifierProvider =
    AsyncNotifierProviderFamily<ChatNotifier, ChatState, String>(
        ChatNotifier.new);

final unreadCountProvider =
    FutureProvider.family<int, String>((ref, jobId) async {
  return ref.read(chatRepositoryProvider).getUnreadCount(jobId);
});
