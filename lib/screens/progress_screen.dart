import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/date_formatters.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _requestTimeout = Duration(seconds: 25);

  final _api = ApiClient.instance;
  final DateTime _weekStart = _mondayOf(DateTime.now());
  QuizStatsOut? _stats;
  StudyPlanDetailOut? _plan;
  String? _statsError;
  String? _planError;
  bool _isLoadingStats = true;
  bool _isLoadingPlan = true;

  static DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingStats = true;
      _isLoadingPlan = true;
      _statsError = null;
      _planError = null;
    });
    await Future.wait<void>([_loadStats(), _loadPlan()]);
  }

  Future<void> _loadStats() async {
    try {
      final statsJson = await _api.getJson('stats').timeout(_requestTimeout);
      final stats = QuizStatsOut.fromJson(statsJson);
      if (mounted) {
        setState(() {
          _stats = stats;
          _statsError = null;
          _isLoadingStats = false;
        });
      }
    } on ApiException catch (error) {
      _setStatsError(error.message);
    } on FormatException catch (error) {
      _setStatsError('İlerleme verileri okunamadı: ${error.message}');
    } on TimeoutException {
      _setStatsError(
        'İstatistikler zamanında yüklenemedi. Bağlantını kontrol edip tekrar dene.',
      );
    } on DioException {
      _setStatsError('Sunucuya bağlanılamadı. Lütfen tekrar dene.');
    } on PlatformException {
      _setStatsError('Oturum bilgileri okunamadı. Yeniden giriş yapıp dene.');
    } on MissingPluginException {
      _setStatsError('Güvenli oturum bilgileri kullanılamıyor.');
    } on TypeError catch (error, stackTrace) {
      debugPrint('Stats response parsing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _setStatsError('İstatistik yanıtı okunamadı: $error');
    } finally {
      if (mounted && _isLoadingStats) {
        _setStatsError('İstatistikler yüklenemedi. Lütfen tekrar dene.');
      }
    }
  }

  void _setStatsError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statsError = message;
      _isLoadingStats = false;
    });
    unawaited(showAppErrorDialog(context, message));
  }

  Future<void> _loadPlan() async {
    try {
      final planJson = await _api
          .getJsonList(
            'study-plans',
            queryParameters: {'week_start': apiDate(_weekStart)},
          )
          .timeout(_requestTimeout);
      final plans = planJson.map(StudyPlanOut.fromJson).toList();
      final plan = plans
          .where((item) => item.weekStart == apiDate(_weekStart))
          .firstOrNull;
      StudyPlanDetailOut? detail;
      if (plan != null) {
        final detailJson = await _api
            .getJson('study-plans/${plan.id}')
            .timeout(_requestTimeout);
        detail = StudyPlanDetailOut.fromJson(detailJson);
      }
      if (mounted) {
        setState(() {
          _plan = detail;
          _planError = null;
          _isLoadingPlan = false;
        });
      }
    } on ApiException catch (error) {
      _setPlanError(error.message);
    } on FormatException catch (error) {
      _setPlanError('Haftalık çalışma verileri okunamadı: ${error.message}');
    } on TimeoutException {
      _setPlanError(
        'Haftalık program zamanında yüklenemedi. Tekrar deneyebilirsin.',
      );
    } on DioException {
      _setPlanError('Haftalık program için sunucuya bağlanılamadı.');
    } on PlatformException {
      _setPlanError('Oturum bilgileri okunamadı. Yeniden giriş yapıp dene.');
    } on MissingPluginException {
      _setPlanError('Güvenli oturum bilgileri kullanılamıyor.');
    } on TypeError {
      _setPlanError('Sunucudan beklenmeyen program yanıtı alındı.');
    } finally {
      if (mounted && _isLoadingPlan) {
        _setPlanError('Haftalık program yüklenemedi. Lütfen tekrar dene.');
      }
    }
  }

  void _setPlanError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _planError = message;
      _isLoadingPlan = false;
    });
    unawaited(showAppErrorDialog(context, message));
  }

  int get _completedMinutes =>
      _plan?.items
          .where((item) => item.isCompleted)
          .fold<int>(0, (total, item) => total + (item.durationMinutes ?? 0)) ??
      0;

  String _durationLabel(int minutes) =>
      '${minutes ~/ 60} sa ${minutes % 60} dk';

  Widget _recentAttemptsChart(List<RecentAttemptStat> attempts) {
    if (attempts.isEmpty) {
      return const AppCard(
        color: AppColors.pale,
        child: Text(
          'Görüntülenecek test sonucu yok.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    final recent = [
      ...attempts,
    ]..sort((first, second) => second.attemptedAt.compareTo(first.attemptedAt));
    final visible = recent.take(7).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son testler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 164,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: visible.map((attempt) {
                final score = attempt.scorePercent.clamp(0, 100).toDouble();
                return Expanded(
                  child: Tooltip(
                    message: '${attempt.quizTitle} · ${score.round()}%',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${score.round()}%',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: 110 * score / 100,
                          decoration: BoxDecoration(
                            color: AppColors.lavender,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateDayMonth(attempt.attemptedAt.toLocal()),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _recommendation(QuizStatsOut stats) {
    if (stats.totalAttempts == 0) {
      return 'Henüz test çözmedin. Fiko’yla bir testle başlayalım!';
    }
    final categories =
        stats.categories
            .where((category) => category.averageScore != null)
            .toList()
          ..sort(
            (first, second) =>
                first.averageScore!.compareTo(second.averageScore!),
          );
    if (categories.isNotEmpty && categories.first.averageScore! < 70) {
      return '${categories.first.categoryName} konusunda tekrar yapmanı öneririm';
    }
    return 'Güzel gidiyorsun, harikasın!';
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'İlerlemen',
    subtitle: 'Öğrenme yolculuğuna göz at.',
    onRefresh: _loadData,
    children: [
      if (_isLoadingStats && _stats == null)
        const AppLoading()
      else if (_statsError != null && _stats == null)
        AppError(message: _statsError!, onRetry: _loadData)
      else if (_stats != null) ...[
        Row(
          children: [
            Expanded(
              child: MetricCard(
                value: _isLoadingPlan
                    ? '…'
                    : _planError == null
                    ? _durationLabel(_completedMinutes)
                    : '—',
                label: 'Bu hafta çalışılan',
                icon: Icons.schedule,
                color: const Color(0xFFE5DCFC),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                value: _stats!.averageScore == null
                    ? '—'
                    : '${_stats!.averageScore!.round()}%',
                label: 'Ortalama skor',
                icon: Icons.insights,
                color: const Color(0xFFFCEBD9),
              ),
            ),
          ],
        ),
        if (_planError != null) ...[
          const SizedBox(height: 8),
          AppError(message: _planError!, onRetry: _loadPlan),
        ],
        const SizedBox(height: 14),
        _recentAttemptsChart(_stats!.recentAttempts),
        const SizedBox(height: 14),
        const SectionHeading('Ders ilerlemesi'),
        if (_stats!.categories.isEmpty)
          const AppCard(
            color: AppColors.pale,
            child: Text(
              'Kategori ilerlemesi için henüz test verisi yok.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _stats!.categories.length;
                  index++
                ) ...[
                  ProgressRow(
                    _stats!.categories[index].categoryName,
                    ((_stats!.categories[index].averageScore ?? 0) / 100)
                        .clamp(0, 1)
                        .toDouble(),
                    detail:
                        '${_stats!.categories[index].attemptCount} test · '
                        '${_stats!.categories[index].averageScore == null ? '—' : '${_stats!.categories[index].averageScore!.round()}%'}',
                  ),
                  if (index < _stats!.categories.length - 1)
                    const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        AppCard(
          color: const Color(0xFFDDEFFA),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.purple,
              size: 30,
            ),
            title: Text(
              _recommendation(_stats!),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ],
  );
}
