import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? email;

  const ForgotPasswordScreen({super.key, this.email});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _emailController = TextEditingController(text: widget.email);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  String? _infoMessage;
  bool _isLoading = false;
  bool _codeRequested = false;
  bool _isReset = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'E-posta adresini gir.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ApiClient.instance.requestPasswordReset(email: email);
      if (mounted) {
        setState(() {
          _codeRequested = true;
          _infoMessage = 'Adres kayıtlıysa şifre sıfırlama kodu e-posta adresine gönderildi.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage = '6 haneli sıfırlama kodunu gir.');
      return;
    }
    if (newPassword.length < 12 || newPassword.length > 128) {
      setState(
        () => _errorMessage = 'Yeni şifre 12 ile 128 karakter arasında olmalı.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ApiClient.instance.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (mounted) {
        setState(() {
          _isReset = true;
          _infoMessage =
              'Şifren güncellendi. Yeni şifrenle giriş yapabilirsin.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ApiClient.instance.requestPasswordReset(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(
          () => _infoMessage =
              'Adres kayıtlıysa yeni bir sıfırlama kodu gönderildi.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editEmail() {
    setState(() {
      _codeRequested = false;
      _codeController.clear();
      _passwordController.clear();
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: DetailPage(
        title: 'Şifremi unuttum',
        subtitle: 'E-posta adresinle şifreni sıfırla.',
        children: [
          const SizedBox(height: 20),
          if (_infoMessage != null)
            AppCard(color: const Color(0xFFE5DCFC), child: Text(_infoMessage!)),
          if (!_isReset) ...[
            TextField(
              controller: _emailController,
              enabled: !_codeRequested,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _decoration('E-posta'),
            ),
            if (!_codeRequested) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isLoading ? null : _requestCode,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sıfırlama kodu gönder'),
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _editEmail,
                  child: const Text('E-postayı değiştir'),
                ),
              ),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: _decoration('6 haneli sıfırlama kodu'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                maxLength: 128,
                decoration: _decoration('Yeni şifre (en az 12 karakter)')
                    .copyWith(
                      counterText: '',
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isLoading ? null : _resendCode,
                child: const Text('Kodu yeniden gönder'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Şifreyi yenile'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              AppError(
                message: _errorMessage!,
                onRetry: _codeRequested ? _resetPassword : _requestCode,
              ),
            ],
          ] else
            FilledButton(
              onPressed: _goToLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Giriş yap'),
            ),
          if (!_isReset)
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text(
                'Giriş ekranına dön',
                style: TextStyle(color: AppColors.purple),
              ),
            ),
        ],
      ),
    ),
  );
}
