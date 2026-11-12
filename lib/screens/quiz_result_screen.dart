import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'schedule_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final AttemptCompletedOut attempt;
  final QuizDetailOut quiz;

  const QuizResultScreen({
    super.key,
    required this.attempt,
    required this.quiz,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final _api = ApiClient.instance;
  AttemptRecommendationOut? _recommendation;
  String? _recommendationError;
  String? _planMessage;
  bool _isLoadingRecommendation = true;
  bool _isSavingPlan = false;
  bool _existingPlanConflict = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    try {
      final json = await _api.getJson(
        'attempts/${widget.attempt.id}/recommendation',
      );
      if (mounted) {
        setState(() {
          _recommendation = AttemptRecommendationOut.fromJson(json);
          _recommendationError = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _recommendationError = error.message);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(
          () => _recommendationError =
              'Kişisel öneri okunamadı: ${error.message}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecommendation = false);
      }
    }
  }

  Future<void> _savePlan() async {
    final recommendation = _recommendation;
    if (recommendation == null || _isSavingPlan) {
      return;
    }
    setState(() {
      _isSavingPlan = true;
      _planMessage = null;
      _existingPlanConflict = false;
    });
    try {
      await _api.postJson(
        'study-plans',
        data: {
          'week_start': recommendation.suggestedPlan.weekStart,
          'items': recommendation.suggestedPlan.items
              .map((item) => item.toJson())
              .toList(),
        },
      );
      _openSchedule();
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        if (mounted) {
          setState(() {
            _existingPlanConflict = true;
            _planMessage = 'Bu hafta için zaten bir programın var.';
          });
        }
      } else if (mounted) {
        setState(() => _planMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPlan = false);
      }
    }
  }

  Future<void> _addItemsToExistingPlan() async {
    final recommendation = _recommendation;
    if (recommendation == null || _isSavingPlan) {
      return;
    }
    setState(() {
      _isSavingPlan = true;
      _planMessage = null;
    });
    try {
      final response = await _api.getJsonList(
        'study-plans',
        queryParameters: {'week_start': recommendation.suggestedPlan.weekStart},
      );
      final plans = response.map(StudyPlanOut.fromJson).toList();
      final plan = plans
          .where(
            (item) => item.weekStart == recommendation.suggestedPlan.weekStart,
          )
          .firstOrNull;
      if (plan == null) {
        throw const ApiException('Bu hafta için mevcut program bulunamadı.');
      }
      for (final item in recommendation.suggestedPlan.items) {
        await _api.postJson(
          'study-plans/${plan.id}/items',
          data: item.toJson(),
        );
      }
      _openSchedule();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _planMessage = error.message);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _planMessage = 'Program okunamadı: ${error.message}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPlan = false);
      }
    }
  }

  void _openSchedule() {
    if (mounted) {
      openPage(context, const ScheduleScreen());
    }
  }

  String _dayName(int day) => switch (day) {
    1 => 'Pazartesi',
    2 => 'Salı',
    3 => 'Çarşamba',
    4 => 'Perşembe',
    5 => 'Cuma',
    6 => 'Cumartesi',
    7 => 'Pazar',
    _ => 'Gün $day',
  };

  Widget _answerCard(AttemptQuestionResultOut answer) {
    final question = widget.quiz.questions
        .where((item) => item.id == answer.questionId)
        .firstOrNull;
    final options = question?.options ?? const <String>[];
    String? textAt(int? index) =>
        index != null && index >= 0 && index < options.length
        ? options[index]
        : null;
    final selectedText = textAt(answer.selectedIndex);
    final correctText = textAt(answer.correctIndex);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer.questionText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: answer.isCorrect
                    ? AppColors.green
                    : const Color(0xFFE68181),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedText == null
                      ? 'Seçimin: Boş bırakıldı'
                      : 'Seçimin: $selectedText',
                ),
              ),
            ],
          ),
          if (!answer.isCorrect) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    correctText == null
                        ? 'Doğru seçenek: ${answer.correctIndex + 1}'
                        : 'Doğru cevap: $correctText',
                  ),
                ),
              ],
            ),
          ],
          if (answer.explanation != null &&
              answer.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              answer.explanation!,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recommendationSection() {
    if (_isLoadingRecommendation) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recommendationError != null) {
      return AppCard(
        color: const Color(0xFFFFEEEE),
        child: Text(
          _recommendationError!,
          style: const TextStyle(color: Color(0xFFB54747)),
        ),
      );
    }
    final recommendation = _recommendation;
    if (recommendation == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: const Color(0xFFE5DCFC),
          child: Text(recommendation.message),
        ),
        if (recommendation.weakTopics.isNotEmpty) ...[
          const SectionHeading('Zayıf konular'),
          ...recommendation.weakTopics.map(
            (topic) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.questionText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (topic.selectedOptionText != null)
                    Text('Seçimin: ${topic.selectedOptionText}'),
                  Text(
                    'Doğru cevap: ${topic.correctOptionText}',
                    style: const TextStyle(color: AppColors.green),
                  ),
                  if (topic.explanation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      topic.explanation!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  if (topic.relatedSummaries.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'İlgili özet kartları',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ...topic.relatedSummaries.map(
                      (summary) => Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text('• ${summary.content}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SectionHeading('Önerilen çalışma programı'),
        if (recommendation.suggestedPlan.items.isEmpty)
          const AppCard(
            color: AppColors.pale,
            child: Text(
              'Önerilen program maddesi yok.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...recommendation.suggestedPlan.items.map(
            (item) => AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.purple,
                ),
                title: Text('${_dayName(item.dayOfWeek)} · ${item.topic}'),
                subtitle: Text(
                  [
                    if (item.startTime != null) item.startTime!,
                    if (item.durationMinutes != null)
                      '${item.durationMinutes} dk',
                  ].join(' · '),
                ),
              ),
            ),
          ),
        if (_planMessage != null)
          AppCard(
            color: _existingPlanConflict
                ? const Color(0xFFFFF3DF)
                : const Color(0xFFFFEEEE),
            child: Text(_planMessage!),
          ),
        FilledButton(
          onPressed: _isSavingPlan ? null : _savePlan,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            minimumSize: const Size.fromHeight(50),
          ),
          child: _isSavingPlan
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Programı kaydet'),
        ),
        if (_existingPlanConflict) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isSavingPlan ? null : _addItemsToExistingPlan,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Mevcut programa ekle'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Test sonucu',
    subtitle: widget.quiz.title,
    children: [
      AppCard(
        color: const Color(0xFFE5DCFC),
        child: Column(
          children: [
            Text(
              '${widget.attempt.scorePercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
            ),
            Text(
              '${widget.attempt.correctCount} / ${widget.attempt.totalQuestions} doğru',
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
      ),
      const SectionHeading('Yanıtların'),
      ...widget.attempt.answers.map(_answerCard),
      const SectionHeading('Kişisel önerin'),
      _recommendationSection(),
    ],
  );
}
