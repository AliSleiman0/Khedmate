import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';

const _tag = 'ChatRepo';

class ChatRepository {
  final ApiClient _api;

  ChatRepository(this._api);

  Future<Map<String, dynamic>> getMessages(
      String jobId, int page, int pageSize) async {
    log.d(_tag, 'getMessages start',
        data: {'jobId': jobId, 'page': page, 'pageSize': pageSize});
    final response = await _api.dio.get(
      '/chat/jobs/$jobId/messages',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(
      String jobId, String text) async {
    log.d(_tag, 'sendMessage start',
        data: {'jobId': jobId, 'len': text.length});
    final response = await _api.dio.post(
      '/chat/jobs/$jobId/messages',
      data: {'text': text},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> markAsRead(String jobId) async {
    log.d(_tag, 'markAsRead', data: {'jobId': jobId});
    await _api.dio.post('/chat/jobs/$jobId/read');
  }

  Future<int> getUnreadCount(String jobId) async {
    final response = await _api.dio.get('/chat/jobs/$jobId/unread-count');
    final body = response.data as Map<String, dynamic>;
    return (body['data']?['unreadCount'] as int?) ?? 0;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(apiClientProvider));
});
