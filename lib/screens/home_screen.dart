import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/date_formatters.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'library_screen.dart';
import 'progress_screen.dart';
import 'schedule_screen.dart';
import 'tutor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient.instance;
  StudyPlanDetailOut? _plan;
  List<CategoryOut> _categories = [];
  List<NoteListOut> _notes = [];
  String? _errorMessage;
  bool _isLoading = true;

  DateTime _mondayOf(DateTime date) {
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
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categoryJson = await _api.getJsonList('categories');
      final categories = categoryJson.map(CategoryOut.fromJson).toList();
      final weekStart = _mondayOf(DateTime.now());
      final planJson = await _api.getJsonList(
        'study-plans',
        queryParameters: {'week_start': apiDate(weekStart)},
      );
      final plans = planJson.map(StudyPlanOut.fromJson).toList();
      final plan = plans
          .where((item) => item.weekStart == apiDate(weekStart))
          .firstOrNull;
      StudyPlanDetailOut? detail;
      if (plan != null) {
        detail = StudyPlanDetailOut.fromJson(
          await _api.getJson('study-plans/${plan.id}'),
        );
      }
      final noteResponses = await Future.wait(
        categories.map(
          (category) => _api.getJsonList(
            'notes',
            queryParameters: {'category_id': category.id},
          ),
        ),
      );
      final notes =
          noteResponses
              .expand((response) => response.map(NoteListOut.fromJson))
              .toList()
            ..sort(
              (first, second) => second.createdAt.compareTo(first.createdAt),
            );
      if (mounted) {
        setState(() {
          _categories = categories;
          _plan = detail;
          _notes = notes.take(2).toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ana sayfa verileri okunamadı: ${error.message}';
          _isLoading = false;
        });
      }
    }
  }

  StudyPlanItemOut? _nextItem(DateTime now) {
    final items = _plan?.items.where((item) {
      if (item.isCompleted || item.dayOfWeek < now.weekday) {
        return false;
      }
      if (item.dayOfWeek > now.weekday || item.startTime == null) {
        return true;
      }
      final time = item.startTime!.split(':');
      if (time.length < 2) {
        return true;
      }
      final hour = int.tryParse(time[0]) ?? 0;
      final minute = int.tryParse(time[1]) ?? 0;
      final second = time.length > 2 ? int.tryParse(time[2]) ?? 0 : 0;
      final itemTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        second,
      );
      return itemTime.isAfter(now);
    }).toList();
    if (items == null || items.isEmpty) {
      return null;
    }
    items.sort((first, second) {
      final dayOrder = first.dayOfWeek.compareTo(second.dayOfWeek);
      if (dayOrder != 0) {
        return dayOrder;
      }
      return (first.startTime ?? '').compareTo(second.startTime ?? '');
    });
    return items.first;
  }

  String _categoryName(String? categoryId) =>
      _categories
          .where((category) => category.id == categoryId)
          .firstOrNull
          ?.name ??
      'Kategorisiz';

  Widget _nextStudyCard(DateTime now) {
    final item = _nextItem(now);
    if (item == null) {
      return AppCard(
        color: const Color(0xFFE5DCFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Henüz programın yok',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => openPage(context, const ScheduleScreen()),
                icon: const Icon(Icons.arrow_forward, color: AppColors.purple),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      color: const Color(0xFFE5DCFC),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white,
            child: Icon(Icons.biotech, color: AppColors.purple, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryName(item.categoryId),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 5),
                Text(
                  item.topic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${weekdayName(item.dayOfWeek)} · ${displayTime(item.startTime)} · '
                  '${item.durationMinutes == null ? 'Süre belirtilmedi' : '${item.durationMinutes} dk'}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => openPage(context, const ScheduleScreen()),
            icon: const Icon(Icons.arrow_forward, color: AppColors.purple),
          ),
        ],
      ),
    );
  }

  Widget _dailyGoalCard(DateTime now) {
    final todayItems =
        _plan?.items.where((item) => item.dayOfWeek == now.weekday).toList() ??
        const <StudyPlanItemOut>[];
    if (todayItems.isEmpty) {
      return const SizedBox.shrink();
    }
    final plannedMinutes = todayItems.fold<int>(
      0,
      (total, item) => total + (item.durationMinutes ?? 0),
    );
    final completedMinutes = todayItems
        .where((item) => item.isCompleted)
        .fold<int>(0, (total, item) => total + (item.durationMinutes ?? 0));
    final progress = plannedMinutes == 0
        ? 0.0
        : (completedMinutes / plannedMinutes).clamp(0, 1).toDouble();
    return Column(
      children: [
        SectionHeading(
          'Günlük hedefin',
          action: 'Detaylar',
          onTap: () => openPage(context, const ProgressScreen()),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bugünkü çalışma',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$completedMinutes dk / $plannedMinutes dk',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: AppColors.purple,
                  backgroundColor: AppColors.bg,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noteStatus(NoteListOut note) => switch (note.indexStatus) {
    'indexed' => const Icon(Icons.check_circle, color: AppColors.green),
    'pending' || 'running' => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
    ),
    'failed' => const Icon(Icons.error_outline, color: Color(0xFFE68181)),
    _ => const Icon(Icons.hourglass_empty, color: AppColors.muted),
  };

  String _statusLabel(NoteListOut note) => switch (note.indexStatus) {
    'indexed' => 'Hazır',
    'pending' || 'running' => 'İndeksleniyor…',
    'failed' => 'Hata',
    _ => note.indexStatus,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AppPage(
      title: 'Merhaba!',
      subtitle: 'Fiko geldi. Bugün ne öğreniyoruz?',
      trailing: const CircleAvatar(
        backgroundColor: AppColors.lavender,
        child: Icon(Icons.person, color: AppColors.purple),
      ),
      onRefresh: _loadData,
      children: [
        if (_isLoading)
          const AppLoading()
        else if (_errorMessage != null)
          AppError(message: _errorMessage!, onRetry: _loadData)
        else ...[
          const SizedBox(height: 8),
          SectionHeading(
            'Sıradaki çalışma',
            action: 'Programı gör',
            onTap: () => openPage(context, const ScheduleScreen()),
          ),
          _nextStudyCard(now),
          const SizedBox(height: 20),
          _dailyGoalCard(now),
          const SizedBox(height: 20),
          SectionHeading(
            'Birlikte öğrenelim',
            action: 'Fiko ile konuş',
            onTap: () => openPage(context, const TutorScreen()),
          ),
          AppCard(
            color: const Color(0xFFDDEFFA),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bir konuda yardıma mı ihtiyacın var?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Bana sor, birlikte keşfedelim.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => openPage(context, const TutorScreen()),
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeading(
            'Ders materyallerin',
            action: 'Tümünü gör',
            onTap: () => openPage(context, const LibraryScreen()),
          ),
          if (_notes.isEmpty)
            const AppCard(
              color: AppColors.pale,
              child: Text(
                'Henüz not eklemedin.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            ..._notes.map(
              (note) => AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.purple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_categoryName(note.categoryId)} · ${_statusLabel(note)}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    _noteStatus(note),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => openPage(context, const LibraryScreen()),
            icon: const Icon(Icons.add),
            label: const Text('PDF yükle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.lavender),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
