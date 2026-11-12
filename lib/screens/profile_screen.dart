import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../core/token_store.dart';
import '../models/api_models.dart';
import '../widgets/app_widgets.dart';
import 'plan_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStore = TokenStore();
  UserPublic? _user;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _tokenStore.readUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kullanıcı bilgisi geçersiz: ${error.message}';
          _isLoading = false;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Kullanıcı bilgisi okunamadı: ${error.message ?? 'bilinmeyen hata'}';
          _isLoading = false;
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Güvenli kullanıcı bilgisi saklama kullanılamıyor.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String? errorMessage;
    try {
      await ApiClient.instance.logout();
    } on ApiException catch (error) {
      errorMessage = error.message;
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    if (errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Profil',
    subtitle: 'Hesabın ve tercihlerin',
    onRefresh: _loadUser,
    children: [
      AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.lavender,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person, color: AppColors.purple, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _isLoading
                  ? const Text(
                      'Kullanıcı bilgisi yükleniyor…',
                      style: TextStyle(color: AppColors.muted),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullName?.trim().isNotEmpty == true
                              ? _user!.fullName!
                              : _user?.email ?? 'Hesap bilgisi bulunamadı',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_user?.fullName?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            _user!.email,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      if (_errorMessage != null)
        AppError(message: _errorMessage!, onRetry: _loadUser),
      AppCard(
        color: const Color(0xFFE5DCFC),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.purple, size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free plan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Plus ile daha fazla öğrenme aracı keşfet',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => openPage(context, const PlanScreen()),
              child: const Text(
                'Planları gör',
                style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ...[
        ('Günlük çalışma hedefi', '60 dakika', Icons.flag_outlined),
        ('Öğrenme tercihleri', 'Ders ve hatırlatmalar', Icons.tune),
        ('Bildirimler', 'Açık', Icons.notifications_none),
        ('Dil', 'Türkçe', Icons.language),
        ('Görünüm', 'Açık tema', Icons.palette_outlined),
        ('Yardım ve destek', 'Bize ulaş', Icons.help_outline),
        ('Oturumu kapat', '', Icons.logout),
      ].map(
        (x) => AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              x.$3,
              color: x.$1 == 'Oturumu kapat'
                  ? const Color(0xFFE68181)
                  : AppColors.purple,
            ),
            title: Text(
              x.$1,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: x.$2.isEmpty
                ? null
                : Text(x.$2, style: const TextStyle(color: AppColors.muted)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
            onTap: x.$1 == 'Oturumu kapat' ? () => _logout(context) : () => {},
          ),
        ),
      ),
    ],
  );
}
