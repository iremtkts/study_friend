import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'chat_screen.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final _api = ApiClient.instance;
  List<CategoryOut> _categories = [];
  List<ConversationOut> _conversations = [];
  String? _selectedCategoryId;
  String? _errorMessage;
  bool? _hasIndexedNotes;
  bool _isLoading = true;
  bool _isCreatingConversation = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.getJsonList('categories');
      final categories = response.map(CategoryOut.fromJson).toList();
      if (!mounted) {
        return;
      }
      final selectedCategoryId =
          categories.any((category) => category.id == _selectedCategoryId)
          ? _selectedCategoryId
          : categories.firstOrNull?.id;
      setState(() {
        _categories = categories;
        _selectedCategoryId = selectedCategoryId;
      });
      if (selectedCategoryId != null) {
        await _loadCategoryContent(selectedCategoryId);
      } else {
        setState(() {
          _conversations = [];
          _hasIndexedNotes = false;
        });
      }
    } on ApiException catch (error) {
      _setError(error.message);
    } on FormatException catch (error) {
      _setError('Kategoriler okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategoryContent(String categoryId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasIndexedNotes = null;
    });
    try {
      final results = await Future.wait([
        _api.getJsonList(
          'conversations',
          queryParameters: {'category_id': categoryId, 'limit': 100},
        ),
        _api.getJsonList('notes', queryParameters: {'category_id': categoryId}),
      ]);
      if (!mounted || categoryId != _selectedCategoryId) {
        return;
      }
      final conversations = results[0].map(ConversationOut.fromJson).toList()
        ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
      final notes = results[1].map(NoteListOut.fromJson).toList();
      setState(() {
        _conversations = conversations;
        _hasIndexedNotes = notes.any((note) => note.indexStatus == 'indexed');
      });
    } on ApiException catch (error) {
      _setError(error.message);
    } on FormatException catch (error) {
      _setError('Sohbet veya not verileri okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
    }
  }

  Future<void> _createConversation() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || _isCreatingConversation) {
      return;
    }
    setState(() {
      _isCreatingConversation = true;
      _errorMessage = null;
    });
    try {
      final json = await _api.postJson(
        'conversations',
        data: {'category_id': categoryId},
      );
      final conversation = ConversationOut.fromJson(json);
      if (mounted) {
        openPage(context, ChatScreen(conversation: conversation));
      }
    } on ApiException catch (error) {
      _setError(error.message);
    } on FormatException catch (error) {
      _setError('Sohbet oluşturulamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isCreatingConversation = false);
      }
    }
  }

  Future<bool> _confirmDelete(ConversationOut conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti sil?'),
        content: const Text('Bu sohbet ve mesajları silinecek.'),
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
      return false;
    }
    try {
      await _api.delete('conversations/${conversation.id}');
      return true;
    } on ApiException catch (error) {
      _setError(error.message);
      return false;
    }
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Fiko ile konuş',
    subtitle: 'Bana sor, birlikte keşfedelim.',
    children: [
      AppCard(
        color: const Color(0xFFE5DCFC),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'Winking Fox Study Mascot.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fiko’yla hangi konuyu keşfediyoruz?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bir kategori seç ve sohbetlerine devam et.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (_errorMessage != null)
        AppCard(
          color: const Color(0xFFFFEEEE),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFB54747)),
          ),
        ),
      if (_isLoading && _categories.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_categories.isEmpty)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Önce bir kategori ve not ekle',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else ...[
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Kategori',
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
            if (value != null && value != _selectedCategoryId) {
              setState(() {
                _selectedCategoryId = value;
                _conversations = [];
              });
              _loadCategoryContent(value);
            }
          },
        ),
        if (_hasIndexedNotes == false)
          const AppCard(
            color: Color(0xFFFFF3DF),
            child: Text(
              'Bu kategoride henüz indekslenmiş not yok. Fiko notlarına henüz bakamıyor.',
              style: TextStyle(color: AppColors.text),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isCreatingConversation ? null : _createConversation,
          icon: _isCreatingConversation
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_comment_outlined),
          label: const Text('Yeni sohbet'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeading('Sohbet geçmişi'),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_conversations.isEmpty)
          const AppCard(
            color: AppColors.pale,
            child: Text(
              'Bu kategoride henüz sohbet yok.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          ..._conversations.map((conversation) {
            final title = conversation.title?.trim();
            return Dismissible(
              key: ValueKey(conversation.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(conversation),
              onDismissed: (_) => setState(
                () => _conversations.removeWhere(
                  (item) => item.id == conversation.id,
                ),
              ),
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.pale,
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.purple,
                    ),
                  ),
                  title: Text(
                    title == null || title.isEmpty ? 'Yeni sohbet' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _dateLabel(conversation.updatedAt),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      openPage(context, ChatScreen(conversation: conversation)),
                  onLongPress: () async {
                    if (await _confirmDelete(conversation) && mounted) {
                      setState(
                        () => _conversations.removeWhere(
                          (item) => item.id == conversation.id,
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }),
      ],
    ],
  );
}
