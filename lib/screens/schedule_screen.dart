import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/date_formatters.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _api = ApiClient.instance;
  late DateTime _weekStart = _mondayOf(DateTime.now());
  int _selectedDay = DateTime.now().weekday;
  StudyPlanDetailOut? _plan;
  List<CategoryOut> _categories = [];
  final Map<String, bool> _completionOverrides = {};
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSavingItem = false;
  int _loadGeneration = 0;

  DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final generation = ++_loadGeneration;
    final weekStart = _weekStart;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categoryJson = await _api.getJsonList('categories');
      final planJson = await _api.getJsonList(
        'study-plans',
        queryParameters: {'week_start': apiDate(weekStart)},
      );
      final categories = categoryJson.map(CategoryOut.fromJson).toList();
      final plans = planJson.map(StudyPlanOut.fromJson).toList();
      final plan = plans
          .where((item) => item.weekStart == apiDate(weekStart))
          .firstOrNull;
      StudyPlanDetailOut? detail;
      if (plan != null) {
        final detailJson = await _api.getJson('study-plans/${plan.id}');
        detail = StudyPlanDetailOut.fromJson(detailJson);
      }
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _categories = categories;
        _plan = detail;
        _completionOverrides.clear();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      }
    } on FormatException catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _errorMessage = 'Program okunamadı: ${error.message}';
          _isLoading = false;
        });
      }
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * offset));
      _completionOverrides.clear();
    });
    _loadPlan();
  }

  bool _isCompleted(StudyPlanItemOut item) =>
      _completionOverrides[item.id] ?? item.isCompleted;

  Future<void> _toggleCompletion(StudyPlanItemOut item, bool completed) async {
    final oldValue = _isCompleted(item);
    setState(() {
      _completionOverrides[item.id] = completed;
      _errorMessage = null;
    });
    try {
      final json = await _api.patchJson(
        'study-plan-items/${item.id}',
        data: {'is_completed': completed},
      );
      final updated = StudyPlanItemOut.fromJson(json);
      if (mounted) {
        setState(() => _completionOverrides[item.id] = updated.isCompleted);
        await _loadPlan();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _completionOverrides[item.id] = oldValue;
          _errorMessage = error.message;
        });
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _completionOverrides[item.id] = oldValue;
          _errorMessage = 'Program maddesi yanıtı okunamadı: ${error.message}';
        });
      }
    }
  }

  Future<void> _deleteItem(StudyPlanItemOut item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maddeyi sil?'),
        content: Text('"${item.topic}" maddesi programdan kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _api.delete('study-plan-items/${item.id}');
      await _loadPlan();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    }
  }

  Future<void> _showAddItemSheet() async {
    final topicController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    var dayOfWeek = _selectedDay;
    var startTime = const TimeOfDay(hour: 9, minute: 0);
    String? categoryId;
    String? validationMessage;

    final draft = await showModalBottomSheet<_StudyPlanItemDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _plan == null ? 'Program oluştur' : 'Madde ekle',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: topicController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Konu',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: dayOfWeek,
                    decoration: const InputDecoration(labelText: 'Gün'),
                    items: List.generate(
                      7,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(weekdayName(index + 1)),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => dayOfWeek = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (pickedTime != null) {
                        setModalState(() => startTime = pickedTime);
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text('Saat: ${displayTime(apiTime(startTime))}'),
                  ),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Süre (dakika)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori (isteğe bağlı)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Kategori seçilmedi'),
                      ),
                      ..._categories.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => categoryId = value),
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      validationMessage!,
                      style: const TextStyle(color: Color(0xFFB54747)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final duration = int.tryParse(
                        durationController.text.trim(),
                      );
                      if (topicController.text.trim().isEmpty) {
                        setModalState(
                          () => validationMessage = 'Konu boş olamaz.',
                        );
                        return;
                      }
                      if (duration == null || duration < 5 || duration > 480) {
                        setModalState(
                          () => validationMessage =
                              'Süre 5 ile 480 dakika arasında olmalı.',
                        );
                        return;
                      }
                      Navigator.pop(
                        context,
                        _StudyPlanItemDraft(
                          topic: topicController.text.trim(),
                          dayOfWeek: dayOfWeek,
                          startTime: startTime,
                          durationMinutes: duration,
                          categoryId: categoryId,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    topicController.dispose();
    durationController.dispose();
    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      _isSavingItem = true;
      _errorMessage = null;
    });
    try {
      var plan = _plan;
      if (plan == null) {
        final response = await _api.postJson(
          'study-plans',
          data: {'week_start': apiDate(_weekStart)},
        );
        plan = StudyPlanDetailOut.fromJson(response);
        if (mounted) {
          setState(() => _plan = plan);
        }
      }
      await _api.postJson(
        'study-plans/${plan.id}/items',
        data: {
          'day_of_week': draft.dayOfWeek,
          'start_time': apiTime(draft.startTime),
          'duration_minutes': draft.durationMinutes,
          'topic': draft.topic,
          'category_id': draft.categoryId,
        },
      );
      if (mounted) {
        setState(() => _selectedDay = draft.dayOfWeek);
        await _loadPlan();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Program oluşturulamadı: ${error.message}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingItem = false);
      }
    }
  }

  String _categoryName(String? categoryId) {
    if (categoryId == null) {
      return 'Kategorisiz';
    }
    return _categories
            .where((category) => category.id == categoryId)
            .firstOrNull
            ?.name ??
        'Kategori';
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [...?_plan?.items]
      ..sort((first, second) {
        final dayComparison = first.dayOfWeek.compareTo(second.dayOfWeek);
        if (dayComparison != 0) {
          return dayComparison;
        }
        return (first.startTime ?? '').compareTo(second.startTime ?? '');
      });
    final selectedItems = allItems
        .where((item) => item.dayOfWeek == _selectedDay)
        .toList();
    final computedCompletedItems = allItems.where(_isCompleted).length;
    final totalItems = _completionOverrides.isEmpty
        ? _plan?.progress.totalItems ?? allItems.length
        : allItems.length;
    final completedItems = _completionOverrides.isEmpty
        ? _plan?.progress.completedItems ?? computedCompletedItems
        : computedCompletedItems;
    final progress = _completionOverrides.isEmpty
        ? ((_plan?.progress.progressPercent ?? 0) / 100).clamp(0, 1).toDouble()
        : (totalItems == 0
              ? 0.0
              : (completedItems / totalItems).clamp(0, 1).toDouble());

    return DetailPage(
      title: 'Haftalık program',
      subtitle: 'Çalışma planını düzenle ve ilerlemeni takip et.',
      onRefresh: _loadPlan,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _changeWeek(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  weekRange(_weekStart),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _changeWeek(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (_isLoading)
          const AppLoading()
        else if (_errorMessage != null)
          AppError(message: _errorMessage!, onRetry: _loadPlan)
        else if (_plan == null)
          AppCard(
            color: AppColors.pale,
            child: Column(
              children: [
                const Text(
                  'Bu hafta için program yok',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSavingItem ? null : _showAddItemSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Program oluştur'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                  ),
                ),
              ],
            ),
          )
        else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Program ilerlemesi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$completedItems / $totalItems · ${(progress * 100).round()}%',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    color: AppColors.purple,
                    backgroundColor: AppColors.bg,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 66,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(7, (index) {
                final day = index + 1;
                final selected = day == _selectedDay;
                final hasItems = allItems.any((item) => item.dayOfWeek == day);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selectedDay = day),
                    child: SizedBox(
                      width: 48,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: selected
                                ? AppColors.purple
                                : Colors.white,
                            foregroundColor: selected
                                ? Colors.white
                                : AppColors.text,
                            child: Text(weekdayShort(day)),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: hasItems
                                  ? (selected
                                        ? AppColors.purple
                                        : AppColors.lavender)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (selectedItems.isEmpty)
            AppCard(
              color: AppColors.pale,
              child: Text(
                '${weekdayName(_selectedDay)} günü için madde yok.',
                style: const TextStyle(color: AppColors.muted),
              ),
            )
          else
            ...selectedItems.map(
              (item) => AppCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        displayTime(item.startTime),
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.topic,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.durationMinutes == null ? 'Süre belirtilmedi' : '${item.durationMinutes} dk'} · ${_categoryName(item.categoryId)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: _isCompleted(item),
                      activeColor: AppColors.green,
                      onChanged: (value) {
                        if (value != null) {
                          _toggleCompletion(item, value);
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Maddeyi sil',
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSavingItem ? null : _showAddItemSheet,
            icon: const Icon(Icons.add),
            label: const Text('Madde ekle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ],
    );
  }
}

class _StudyPlanItemDraft {
  final String topic;
  final int dayOfWeek;
  final TimeOfDay startTime;
  final int durationMinutes;
  final String? categoryId;

  const _StudyPlanItemDraft({
    required this.topic,
    required this.dayOfWeek,
    required this.startTime,
    required this.durationMinutes,
    required this.categoryId,
  });
}
