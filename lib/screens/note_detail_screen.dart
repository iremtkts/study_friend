import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/job_poller.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'chat_screen.dart';
import 'quiz_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteListOut note;
  final String categoryName;

  const NoteDetailScreen({
    super.key,
    required this.note,
    required this.categoryName,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _api = ApiClient.instance;
  List<SummaryOut> _summaries = [];
  String? _errorMessage;
  bool _isLoadingSummaries = true;
  bool _isGenerating = false;
  bool _isStartingConversation = false;

  void _reportError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = message);
    unawaited(showAppErrorDialog(context, message));
  }

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    try {
      final response = await _api.getJsonList(
        'notes/${widget.note.id}/summaries',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summaries = response.map(SummaryOut.fromJson).toList();
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      _reportError(error.message);
    } on FormatException catch (error) {
      _reportError('Özet kartları okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSummaries = false);
      }
    }
  }

  Future<void> _generateSummaries() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    try {
      await withFikoProgress<void>(
        context,
        message: 'Özet kartları hazırlanıyor. Bu işlem biraz sürebilir.',
        action: () async {
          final job = await _api.postJson(
            'notes/${widget.note.id}/summaries/generate',
          );
          final jobId = job['job_id'];
          if (jobId is! String || jobId.isEmpty) {
            throw const FormatException('İş yanıtında job_id bulunamadı.');
          }
          await waitForJob(jobId);
        },
      );
      await _loadSummaries();
    } on ApiException catch (error) {
      _reportError(_localizedError(error));
    } on FormatException catch (error) {
      _reportError('İş yanıtı okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateQuiz() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    try {
      final result = await withFikoProgress<AIJobOut>(
        context,
        message: 'Fiko senin için test hazırlıyor. Bu işlem biraz sürebilir.',
        action: () async {
          final job = await _api.postJson(
            'notes/${widget.note.id}/quizzes/generate',
            data: {'question_count': 5},
          );
          final jobId = job['job_id'];
          if (jobId is! String || jobId.isEmpty) {
            throw const FormatException('İş yanıtında job_id bulunamadı.');
          }
          return waitForJob(jobId);
        },
      );
      final quizId = result.resultId;
      if (quizId == null || quizId.isEmpty) {
        throw const ApiException(
          'Oluşturulan testin kimliği sunucu yanıtında bulunamadı.',
        );
      }
      if (mounted) {
        openPage(context, QuizScreen(quizId: quizId));
      }
    } on ApiException catch (error) {
      _reportError(_localizedError(error));
    } on FormatException catch (error) {
      _reportError('İş yanıtı okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _startNoteConversation() async {
    if (_isStartingConversation) {
      return;
    }
    setState(() {
      _isStartingConversation = true;
      _errorMessage = null;
    });
    try {
      final json = await _api.postJson(
        'conversations',
        data: {
          'category_id': widget.note.categoryId,
          'note_id': widget.note.id,
        },
      );
      final conversation = ConversationOut.fromJson(json);
      if (mounted) {
        openPage(context, ChatScreen(conversation: conversation));
      }
    } on ApiException catch (error) {
      _reportError(error.message);
    } on FormatException catch (error) {
      _reportError('Sohbet oluşturulamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isStartingConversation = false);
      }
    }
  }

  String _localizedError(ApiException error) => switch (error.statusCode) {
    409 => 'Bu not şu anda işlenemiyor. İndeksleme tamamlandıktan sonra tekrar deneyin.',
    422 => 'Notun içeriği bu işlem için uygun değil. Dosyanın okunabildiğini kontrol edin.',
    429 => 'Çok fazla istek gönderildi. Lütfen biraz bekleyip tekrar deneyin.',
    503 =>
      'AI hizmeti şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
    _ => error.message,
  };

  Widget _indexStatus() => switch (widget.note.indexStatus) {
    'indexed' => const Chip(
      avatar: Icon(Icons.check_circle, color: AppColors.green, size: 18),
      label: Text('Hazır'),
    ),
    'pending' || 'running' => const Chip(
      avatar: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: Text('İndeksleniyor…'),
    ),
    'failed' => const Chip(
      avatar: Icon(Icons.error_outline, color: Color(0xFFE68181)),
      label: Text('Hata'),
    ),
    _ => Chip(label: Text(widget.note.indexStatus)),
  };

  @override
  Widget build(BuildContext context) => DetailPage(
    title: widget.note.displayTitle,
    subtitle: widget.categoryName,
    onRefresh: _loadSummaries,
    children: [
      AppCard(
        child: Row(
          children: [
            const Icon(Icons.folder_outlined, color: AppColors.purple),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.categoryName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _indexStatus(),
          ],
        ),
      ),
      if (_errorMessage != null)
        AppCard(
          color: const Color(0xFFFFEEEE),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFB54747)),
          ),
        ),
      if (_isGenerating)
        const AppCard(
          color: Color(0xFFE5DCFC),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Hazırlanıyor, bu 1 dakika kadar sürebilir…'),
              ),
            ],
          ),
        ),
      FilledButton.icon(
        onPressed: _isGenerating ? null : _generateSummaries,
        icon: const Icon(Icons.style_outlined),
        label: const Text('Özet kartları oluştur'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.purple,
          minimumSize: const Size.fromHeight(50),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _isGenerating ? null : _generateQuiz,
        icon: const Icon(Icons.quiz_outlined),
        label: const Text('Fiko ile test çöz'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          minimumSize: const Size.fromHeight(50),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _isGenerating || _isStartingConversation
            ? null
            : _startNoteConversation,
        icon: _isStartingConversation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chat_bubble_outline),
            label: const Text('Fiko ile konuş'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      ),
      const SizedBox(height: 20),
      const SectionHeading('Özet kartları'),
      if (_isLoadingSummaries)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_summaries.isEmpty)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Bu not için henüz özet kartı yok.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else
        ..._summaries.map(
          (summary) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kart ${summary.position}',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(summary.content),
              ],
            ),
          ),
        ),
    ],
  );
}
