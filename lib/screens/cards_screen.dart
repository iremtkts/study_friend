import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'flashcard_screen.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<CategoryOut> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.instance.getJsonList('categories');
      if (mounted) {
        setState(() {
          _categories = response.map(CategoryOut.fromJson).toList();
        });
      }
    } on ApiException catch (error) {
      _reportError(error.message);
    } on FormatException catch (error) {
      _reportError('Kategoriler okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Çalışma kartları',
    subtitle: 'Hatırlamak için pratik yap.',
    onRefresh: _loadCategories,
    children: [
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_errorMessage != null)
        AppCard(
          color: const Color(0xFFFFEEEE),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFB54747)),
          ),
        )
      else if (_categories.isEmpty)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Henüz bir kategorin yok.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else
        ..._categories.map(
          (category) => FeatureTile(
            title: category.name,
            subtitle: 'Özet kartlarını gör',
            icon: Icons.style,
            color: const Color(0xFFE5DCFC),
            onTap: () => openPage(
              context,
              FlashcardScreen(
                categoryId: category.id,
                categoryName: category.name,
              ),
            ),
          ),
        ),
    ],
  );
}
