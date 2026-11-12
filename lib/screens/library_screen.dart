import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/job_poller.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'note_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _maxFileBytes = 10 * 1024 * 1024;

  final _api = ApiClient.instance;
  final _searchController = TextEditingController();
  final Set<String> _indexingNoteIds = {};
  List<CategoryOut> _categories = [];
  List<NoteListOut> _notes = [];
  String? _selectedCategoryId;
  String? _errorMessage;
  String? _uploadMessage;
  bool _isLoading = true;
  bool _isUploading = false;
  int _notesRequestId = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final response = await _api.getJsonList('categories');
      final categories = response.map(CategoryOut.fromJson).toList();
      if (!mounted) {
        return;
      }
      final selectedCategoryId =
          categories.any((category) => category.id == _selectedCategoryId)
          ? _selectedCategoryId
          : null;
      setState(() {
        _categories = categories;
        _selectedCategoryId = selectedCategoryId;
      });
      await _loadNotes();
    } on ApiException catch (error) {
      _setError(error);
    } on FormatException catch (error) {
      _setError(ApiException('Kategori yanıtı okunamadı: ${error.message}'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotes({bool showErrorAlert = true}) async {
    final requestId = ++_notesRequestId;
    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      if (mounted) {
        setState(() => _notes = []);
        _updatePolling();
      }
      return;
    }
    try {
      final response = await _api.getJsonList(
        'notes',
        queryParameters: {'category_id': categoryId},
      );
      if (!mounted ||
          requestId != _notesRequestId ||
          categoryId != _selectedCategoryId) {
        return;
      }
      setState(() {
        _notes = response.map(NoteListOut.fromJson).toList();
        _errorMessage = null;
      });
      _updatePolling();
    } on ApiException catch (error) {
      if (requestId == _notesRequestId) {
        _setError(error, showAlert: showErrorAlert);
      }
    } on FormatException catch (error) {
      if (requestId == _notesRequestId) {
        _setError(
          ApiException('Not listesi okunamadı: ${error.message}'),
          showAlert: showErrorAlert,
        );
      }
    }
  }

  void _updatePolling() {
    _pollTimer?.cancel();
    if (_isUploading) {
      return;
    }
    if (_notes.any(
      (note) => note.indexStatus == 'pending' || note.indexStatus == 'running',
    )) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadNotes(showErrorAlert: false),
      );
    }
  }

  void _setError(ApiException error, {bool showAlert = true}) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = error.message);
    if (showAlert) {
      unawaited(showAppErrorDialog(context, error.message));
    }
  }

  Future<void> _waitForIndexing(String noteId, String categoryId) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(minutes: 3)) {
      final response = await _api.getJsonList(
        'notes',
        queryParameters: {'category_id': categoryId},
      );
      final notes = response.map(NoteListOut.fromJson).toList();
      if (!mounted) {
        return;
      }
      if (_selectedCategoryId == categoryId) {
        setState(() => _notes = notes);
        _updatePolling();
      }
      final note = notes.where((item) => item.id == noteId).firstOrNull;
      if (note?.indexStatus == 'indexed') {
        return;
      }
      if (note?.indexStatus == 'failed') {
        throw const ApiException(
          'Not indekslenemedi. Dosyanın okunabilir olduğunu kontrol edip tekrar deneyin.',
        );
      }
      final remaining = const Duration(minutes: 3) - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        break;
      }
      await Future<void>.delayed(
        remaining < const Duration(seconds: 5)
            ? remaining
            : const Duration(seconds: 5),
      );
    }
    throw const ApiException(
      'Not indeksleme işlemi zamanında tamamlanmadı. Lütfen kütüphanedeki durumdan tekrar kontrol edin.',
    );
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Kategori adı'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null) {
      return;
    }
    if (name.isEmpty) {
      _setError(const ApiException('Kategori adı boş olamaz.'));
      return;
    }
    try {
      final json = await _api.postJson('categories', data: {'name': name});
      final category = CategoryOut.fromJson(json);
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = [..._categories, category];
        _selectedCategoryId = category.id;
        _notes = [];
        _errorMessage = null;
      });
      await _loadNotes();
    } on ApiException catch (error) {
      _setError(error);
    } on FormatException catch (error) {
      _setError(ApiException('Kategori yanıtı okunamadı: ${error.message}'));
    }
  }

  Future<void> _pickAndUpload() async {
    if (_selectedCategoryId == null || _isUploading) {
      return;
    }
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'txt'],
      );
      if (files.isEmpty) {
        return;
      }
      final file = files.first;
      final fileSize = await file.length();
      if (fileSize == null) {
        _setError(const ApiException('Dosya boyutu okunamadı.'));
        return;
      }
      if (fileSize > _maxFileBytes) {
        _setError(const ApiException('Dosya boyutu 10 MB sınırını aşıyor.'));
        return;
      }
      final extension = file.extension?.toLowerCase();
      if (extension != 'pdf' && extension != 'txt') {
        _setError(
          const ApiException('Yalnızca PDF ve TXT dosyaları seçilebilir.'),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxFileBytes) {
        _setError(const ApiException('Dosya boyutu 10 MB sınırını aşıyor.'));
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = true;
        _errorMessage = null;
        _uploadMessage = null;
      });
      final formData = FormData.fromMap({
        'category_id': _selectedCategoryId,
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final categoryId = _selectedCategoryId!;
      await withFikoProgress<void>(
        context,
        message: 'Dosyan yükleniyor ve indeksleniyor. Bu biraz sürebilir.',
        action: () async {
          final json = await _api.postMultipart('notes', data: formData);
          final note = NoteListOut.fromJson(json);
          await _waitForIndexing(note.id, categoryId);
        },
      );
      if (!mounted) {
        return;
      }
      setState(() => _uploadMessage = 'Dosya yüklendi ve kullanıma hazır.');
      await _loadNotes(showErrorAlert: false);
    } on ApiException catch (error) {
      _setError(error);
    } on PlatformException catch (error) {
      _setError(
        ApiException('Dosya seçilemedi: ${error.message ?? 'bilinmeyen hata'}'),
      );
    } on FormatException catch (error) {
      _setError(ApiException('Dosya yanıtı okunamadı: ${error.message}'));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
        _updatePolling();
      }
    }
  }

  Future<void> _retryIndex(NoteListOut note) async {
    if (!_indexingNoteIds.add(note.id)) {
      return;
    }
    setState(() {});
    try {
      await withFikoProgress<void>(
        context,
        message: 'Fiko notunu yeniden indeksliyor. Bu biraz sürebilir.',
        action: () async {
          final json = await _api.postJson('notes/${note.id}/index');
          final jobId = json['job_id'];
          if (jobId is! String || jobId.isEmpty) {
            throw const FormatException('İş yanıtında job_id bulunamadı.');
          }
          await waitForJob(jobId);
        },
      );
      await _loadNotes(showErrorAlert: false);
    } on ApiException catch (error) {
      _setError(error);
    } on FormatException catch (error) {
      _setError(ApiException('İş yanıtı okunamadı: ${error.message}'));
    } finally {
      if (mounted) {
        setState(() => _indexingNoteIds.remove(note.id));
      }
    }
  }

  Widget _statusBadge(NoteListOut note) {
    switch (note.indexStatus) {
      case 'indexed':
        return const Chip(
          avatar: Icon(Icons.check_circle, color: AppColors.green, size: 18),
          label: Text('Hazır'),
          visualDensity: VisualDensity.compact,
        );
      case 'failed':
        final isRetrying = _indexingNoteIds.contains(note.id);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isRetrying ? null : () => _retryIndex(note),
          child: Chip(
            avatar: isRetrying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.error_outline, color: Color(0xFFE68181)),
            label: const Text('Hata · yeniden dene'),
            visualDensity: VisualDensity.compact,
          ),
        );
      case 'pending':
      case 'running':
        return const Chip(
          avatar: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text('İndeksleniyor…'),
          visualDensity: VisualDensity.compact,
        );
      default:
        return Chip(
          label: Text(note.indexStatus),
          visualDensity: VisualDensity.compact,
        );
    }
  }

  Widget _noteTile(NoteListOut note, CategoryOut category) => AppCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        note.originalFilename.toLowerCase().endsWith('.pdf')
            ? Icons.picture_as_pdf
            : Icons.description_outlined,
        color: AppColors.purple,
      ),
      title: Text(
        note.displayTitle,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.name, style: const TextStyle(color: AppColors.muted)),
          _statusBadge(note),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: () => openPage(
        context,
        NoteDetailScreen(note: note, categoryName: category.name),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'PDF kütüphanesi',
    subtitle: 'Belgelerini derslerine göre düzenle.',
    onRefresh: _refreshAll,
    children: [
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Belgelerde ara',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      if (_errorMessage != null)
        AppCard(
          color: const Color(0xFFFFEEEE),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFB54747)),
          ),
        ),
      if (_uploadMessage != null)
        AppCard(
          color: const Color(0xFFE1F2EA),
          child: Text(
            _uploadMessage!,
            style: const TextStyle(color: AppColors.text),
          ),
        ),
      AppCard(
        color: const Color(0xFFE5DCFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni materyal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ders kategorisi',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              hint: const Text('Kategori seç'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _notes = [];
                  _uploadMessage = null;
                });
                _loadNotes();
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('Kategori ekle'),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _selectedCategoryId == null || _isUploading
                  ? null
                  : _pickAndUpload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Yükleniyor…' : 'Dosya seç ve yükle'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_categories.isEmpty)
        AppCard(
          color: AppColors.pale,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Henüz kategorin yok. Belgelerini düzenlemek için kategori ekle.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              TextButton(
                onPressed: _addCategory,
                child: const Text('Kategori ekle'),
              ),
            ],
          ),
        )
      else if (_selectedCategoryId == null)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Notları görmek için bir kategori seç.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else ...[
        SectionHeading(
          _categories
                  .where((category) => category.id == _selectedCategoryId)
                  .firstOrNull
                  ?.name ??
              'Notlar',
        ),
        ..._notes
            .where(
              (note) => note.displayTitle.toLowerCase().contains(
                _searchController.text.trim().toLowerCase(),
              ),
            )
            .map(
              (note) => _noteTile(
                note,
                _categories.firstWhere(
                  (category) => category.id == note.categoryId,
                ),
              ),
            ),
        if (_notes.isEmpty)
          const AppCard(
            color: AppColors.pale,
            child: Text(
              'Bu kategoride henüz not yok.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
      ],
    ],
  );
}
