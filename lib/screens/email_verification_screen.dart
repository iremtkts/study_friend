import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? initialMessage;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.initialMessage,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  String? _errorMessage;
  String? _infoMessage;
  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _infoMessage =
        widget.initialMessage ??
        'E-posta adresine gönderilen 6 haneli doğrulama kodunu gir.';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage = '6 haneli doğrulama kodunu gir.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ApiClient.instance.verifyEmail(email: widget.email, code: code);
      if (mounted) {
        setState(() {
          _isVerified = true;
          _infoMessage = 'E-posta adresin doğrulandı. Giriş yapabilirsin.';
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

  Future<void> _resend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ApiClient.instance.resendVerification(email: widget.email);
      if (mounted) {
        setState(
          () => _infoMessage =
              'Doğrulama kodu gönderildiyse e-posta kutunu kontrol et.',
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

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: DetailPage(
        title: 'E-posta doğrulama',
        subtitle: widget.email,
        children: [
          const SizedBox(height: 20),
          if (_infoMessage != null)
            AppCard(color: const Color(0xFFE5DCFC), child: Text(_infoMessage!)),
          if (!_isVerified) ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: '6 haneli doğrulama kodu',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              AppError(message: _errorMessage!, onRetry: _verify),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isLoading ? null : _verify,
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
                  : const Text('E-postayı doğrula'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resend,
              child: const Text(
                'Doğrulama kodunu yeniden gönder',
                style: TextStyle(color: AppColors.purple),
              ),
            ),
          ] else
            FilledButton(
              onPressed: _goToLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Giriş yap'),
            ),
        ],
      ),
    ),
  );
}
