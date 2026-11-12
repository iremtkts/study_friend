import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';

class FlashcardScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const FlashcardScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final _pageController = PageController();
  List<SummaryOut> _cards = [];
  int _totalCardCount = 0;
  int _currentPage = 0;
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
    _loadCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.instance.getJsonList(
        'summaries',
        queryParameters: {'category_id': widget.categoryId},
      );
      if (mounted) {
        final allCards = response.map(SummaryOut.fromJson).toList()
          ..sort((first, second) => first.position.compareTo(second.position));
        setState(() {
          _totalCardCount = allCards.length;
          _cards = allCards.skip(2).toList();
          _currentPage = 0;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
    } on ApiException catch (error) {
      _reportError(error.message);
    } on FormatException catch (error) {
      _reportError('Kartlar okunamadı: ${error.message}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _advanceCard() {
    if (_cards.isEmpty) {
      return;
    }
    setState(() {
      if (_currentPage < _cards.length - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => DetailPage(
    title: '${widget.categoryName} kartları',
    subtitle: _cards.isEmpty
        ? 'Hatırlamak için pratik yap.'
        : 'Kart ${_currentPage + 3} / $_totalCardCount',
    onRefresh: _loadCards,
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
      else if (_cards.isEmpty)
        const AppCard(
          color: AppColors.pale,
          child: Text(
            'Bu kategoride çalışılacak özet kartı yok.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else ...[
        LinearProgressIndicator(
          value: (_currentPage + 1) / _cards.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.purple,
          backgroundColor: AppColors.bg,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cards.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AppCard(
                color: const Color(0xFFE5DCFC),
                child: SizedBox(
                  height: 300,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        _cards[index].content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _advanceCard,
                child: const Text('Tekrar et'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _advanceCard,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                ),
                child: const Text('İlerle'),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
