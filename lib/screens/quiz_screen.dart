import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String? quizId;

  const QuizScreen({super.key, this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _api = ApiClient.instance;
  List<CategoryOut> _categories = [];
  List<QuizListOut> _quizzes = [];
  QuizDetailOut? _quiz;
  AttemptInProgressOut? _attempt;
  String? _selectedCategoryId;
  final Map<String, int> _answers = {};
  int _currentQuestion = 0;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmissionLocked = false;

  @override
  void initState() {
    super.initState();
    if (widget.quizId == null) {
      _loadCategories();
    } else {
      _loadQuizAndStart(widget.quizId!);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.getJsonList('categories');
      if (mounted) {
        setState(
          () => _categories = response.map(CategoryOut.fromJson).toList(),
        );
      }
    } on ApiException catch (error) {
      _showError(error.message);
    } on FormatException catch (error) {
      _showError('Kategoriler okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadQuizzes(String categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _quizzes = [];
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.getJsonList(
        'quizzes',
        queryParameters: {'category_id': categoryId},
      );
      if (mounted && _selectedCategoryId == categoryId) {
        setState(() => _quizzes = response.map(QuizListOut.fromJson).toList());
      }
    } on ApiException catch (error) {
      _showError(error.message);
    } on FormatException catch (error) {
      _showError('Test listesi okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadQuizAndStart(String quizId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final quizJson = await _api.getJson('quizzes/$quizId');
      final quiz = QuizDetailOut.fromJson(quizJson);
      if (quiz.questions.isEmpty) {
        throw const ApiException('Bu testte yanıtlanacak soru yok.');
      }
      final attemptJson = await _api.postJson('quizzes/$quizId/attempts');
      final attempt = AttemptInProgressOut.fromJson(attemptJson);
      if (mounted) {
        setState(() {
          _quiz = quiz;
          _attempt = attempt;
          _currentQuestion = 0;
          _answers.clear();
        });
      }
    } on ApiException catch (error) {
      _showError(error.message);
    } on FormatException catch (error) {
      _showError('Test başlatılamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAttempt() async {
    final quiz = _quiz;
    final attempt = _attempt;
    if (_isSubmissionLocked ||
        _isSubmitting ||
        quiz == null ||
        attempt == null) {
      return;
    }
    _isSubmissionLocked = true;
    var didSubmit = false;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final payload = {
        'answers': quiz.questions
            .map(
              (question) => {
                'question_id': question.id,
                'selected_index': _answers[question.id],
              },
            )
            .toList(),
      };
      final resultJson = await _api.postJson(
        'attempts/${attempt.id}/submit',
        data: payload,
      );
      final result = AttemptCompletedOut.fromJson(resultJson);
      didSubmit = true;
      if (mounted) {
        openPage(context, QuizResultScreen(attempt: result, quiz: quiz));
      }
    } on ApiException catch (error) {
      _isSubmissionLocked = false;
      _showError(error.message);
    } on FormatException catch (error) {
      _isSubmissionLocked = false;
      _showError('Test sonucu okunamadı: ${error.message}');
    } finally {
      if (!didSubmit) {
        _isSubmissionLocked = false;
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
      unawaited(showAppErrorDialog(context, message));
    }
  }

  Widget _buildCatalog() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_errorMessage != null)
        AppCard(
          color: const Color(0xFFFFEEEE),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFB54747)),
          ),
        ),
      if (_categories.isEmpty && !_isLoading)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Henüz bir kategorin yok.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          hint: const Text('Kategori seç'),
          decoration: InputDecoration(
            labelText: 'Ders kategorisi',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          items: _categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _loadQuizzes(value);
            }
          },
        ),
      const SizedBox(height: 16),
      if (_isLoading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        )
      else if (_selectedCategoryId == null)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Testleri görmek için bir kategori seç.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else if (_quizzes.isEmpty)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Bu kategoride henüz test yok.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else
        ..._quizzes.map(
          (quiz) => FeatureTile(
            title: quiz.title,
            subtitle: '${quiz.questionCount} soru',
            icon: Icons.quiz_outlined,
            color: const Color(0xFFE5DCFC),
            onTap: () => openPage(context, QuizScreen(quizId: quiz.id)),
          ),
        ),
    ],
  );

  Widget _buildQuestion() {
    final quiz = _quiz!;
    final question = quiz.questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / quiz.questions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null)
          AppCard(
            color: const Color(0xFFFFEEEE),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB54747)),
            ),
          ),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.purple,
          backgroundColor: AppColors.bg,
        ),
        const SizedBox(height: 8),
        Text(
          'Soru ${_currentQuestion + 1} / ${quiz.questions.length}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Text(
            question.questionText,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ...question.options.indexed.map((entry) {
          final index = entry.$1;
          final option = entry.$2;
          final selected = _answers[question.id] == index;
          return AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: AppColors.purple,
              ),
              title: Text(option),
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _answers[question.id] = index),
            ),
          );
        }),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _isSubmitting
              ? null
              : _currentQuestion < quiz.questions.length - 1
              ? () => setState(() => _currentQuestion++)
              : _submitAttempt,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            minimumSize: const Size.fromHeight(52),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _currentQuestion < quiz.questions.length - 1
                      ? 'Sonraki'
                      : 'Bitir',
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => DetailPage(
    title: _quiz?.title ?? 'Mini quiz',
    subtitle: _quiz == null ? 'Testlerini çöz ve ilerlemeni gör.' : 'Test',
    children: [
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_quiz != null)
        _buildQuestion()
      else
        _buildCatalog(),
    ],
  );
}
