import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/job_poller.dart';
import '../models/api_models.dart';

class ChatScreen extends StatefulWidget {
  final ConversationOut conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const _suggestions = [
    'Bu notun ana başlıklarını özetle',
    'Önemli kavramları listele',
    'Beni sına: bir soru sor',
  ];

  final _api = ApiClient.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ConversationMessageOut> _messages = [];
  List<NoteListOut> _notes = [];
  CancelToken? _pollCancelToken;
  String? _errorMessage;
  String? _failedMessage;
  String? _assistantError;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollCancelToken?.cancel('Chat screen disposed');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadConversation() async {
    try {
      final detailJson = await _api.getJson(
        'conversations/${widget.conversation.id}',
        queryParameters: const {'messages_limit': 100},
      );
      final noteJson = await _api.getJsonList(
        'notes',
        queryParameters: {'category_id': widget.conversation.categoryId},
      );
      final detail = ConversationDetailOut.fromJson(detailJson);
      final notes = noteJson.map(NoteListOut.fromJson).toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(detail.messages);
        _notes = notes;
        _errorMessage = null;
        _isLoading = false;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } on FormatException catch (error) {
      _setLoadError('Sohbet okunamadı: ${error.message}');
    }
  }

  void _setLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? suggestion]) async {
    if (_isSending) {
      return;
    }
    final content = (suggestion ?? _messageController.text).trim();
    if (content.isEmpty || content.length > 4000) {
      return;
    }
    if (suggestion == null) {
      _messageController.clear();
    }
    final optimisticMessage = ConversationMessageOut(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: content,
      sources: const [],
      modelName: null,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(optimisticMessage);
      _isSending = true;
      _errorMessage = null;
      _assistantError = null;
      _failedMessage = null;
    });
    _scrollToBottom();
    final cancelToken = CancelToken();
    _pollCancelToken = cancelToken;
    try {
      final response = await _api.postJson(
        'conversations/${widget.conversation.id}/chat',
        data: {'content': content},
      );
      final chatJob = ChatJobOut.fromJson(response);
      await waitForJob(chatJob.jobId, cancelToken: cancelToken);
      if (!mounted) {
        return;
      }
      await _loadConversation();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _failedMessage = content;
          _assistantError = _localizedChatError(error);
        });
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _failedMessage = content;
          _assistantError = 'Sohbet yanıtı okunamadı: ${error.message}';
        });
      }
    } on DioException catch (error) {
      if (mounted && !CancelToken.isCancel(error)) {
        setState(() {
          _failedMessage = content;
          _assistantError = 'Yanıt alınamadı. Lütfen tekrar dene.';
        });
      }
    } finally {
      if (identical(_pollCancelToken, cancelToken)) {
        _pollCancelToken = null;
      }
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  String _localizedChatError(ApiException error) => switch (error.statusCode) {
    409 => 'Önceki cevap hâlâ hazırlanıyor.',
    429 => 'Günlük sohbet limitine ulaştın.',
    503 => 'AI servisi şu an hazır değil.',
    _ => error.message,
  };

  String? _sourceTitle(String source) {
    for (final note in _notes) {
      if (note.id == source ||
          note.displayTitle == source ||
          note.originalFilename == source) {
        return note.displayTitle;
      }
    }
    return null;
  }

  Widget _messageBubble(ConversationMessageOut message) {
    final isUser = message.role == 'user';
    final sourceTitles = isUser
        ? const <String>[]
        : message.sources
              .map(_sourceTitle)
              .whereType<String>()
              .toSet()
              .toList();
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.purple : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.text.withValues(alpha: .05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppColors.text,
                    height: 1.4,
                  ),
                ),
              ),
              ...sourceTitles.map(
                (title) => Padding(
                  padding: const EdgeInsets.only(top: 5, left: 8, right: 8),
                  child: Text(
                    'Kaynak: $title',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thinkingBubble() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20)
            .copyWith(bottomLeft: const Radius.circular(5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.purple,
            ),
          ),
          SizedBox(width: 10),
          Text('Fiko düşünüyor…', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    ),
  );

  Widget _failureBubble() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _assistantError ?? 'Yanıt alınamadı.',
            style: const TextStyle(color: Color(0xFFB54747)),
          ),
          if (_failedMessage != null)
            TextButton.icon(
              onPressed: _isSending ? null : () => _sendMessage(_failedMessage),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
        ],
      ),
    ),
  );

  Widget _emptySuggestions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text(
        'Bana sor, birlikte keşfedelim.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 10),
      ..._suggestions.map(
        (suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ActionChip(
            label: Text(suggestion),
            avatar: const Icon(
              Icons.auto_awesome,
              color: AppColors.purple,
              size: 18,
            ),
            onPressed: _isSending ? null : () => _sendMessage(suggestion),
          ),
        ),
      ),
    ],
  );

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    decoration: BoxDecoration(
      color: AppColors.bg,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Focus(
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                if (!_isSending) {
                  _sendMessage();
                }
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _messageController,
              enabled: !_isSending,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Mesajını yaz...',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _isSending ? null : _sendMessage,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.purple,
            disabledBackgroundColor: AppColors.lavender,
          ),
          icon: const Icon(Icons.send_rounded, color: Colors.white),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                widget.conversation.title?.trim().isNotEmpty == true
                    ? widget.conversation.title!
                    : 'Yeni sohbet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
      if (_errorMessage != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB54747)),
            ),
          ),
        ),
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  if (_messages.isEmpty) _emptySuggestions(),
                  ..._messages.map(_messageBubble),
                  if (_isSending) _thinkingBubble(),
                  if (!_isSending && _assistantError != null) _failureBubble(),
                ],
              ),
      ),
      _composer(),
    ],
  );
}
