import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

Future<void> showAppErrorDialog(BuildContext context, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bir sorun oluştu'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

Future<T> withFikoProgress<T>(
  BuildContext context, {
  required String message,
  required Future<T> Function() action,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.pale,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFE5DCFC),
                child: ClipOval(
                  child: Image.asset(
                    'Winking Fox Study Mascot.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fiko düşünüyor…',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              const LinearProgressIndicator(color: AppColors.purple),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await action();
  } finally {
    if (navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
  }
}

class AppPage extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const AppPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
    this.onRefresh,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
      Expanded(
        child: Builder(
          builder: (context) {
            final listView = ListView(
              physics: onRefresh == null
                  ? null
                  : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: children,
            );
            if (onRefresh == null) {
              return listView;
            }
            return RefreshIndicator(onRefresh: onRefresh!, child: listView);
          },
        ),
      ),
    ],
  );
}

class DetailPage extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const DetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onRefresh,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Builder(
          builder: (context) {
            final listView = ListView(
              physics: onRefresh == null
                  ? null
                  : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: children,
            );
            if (onRefresh == null) {
              return listView;
            }
            return RefreshIndicator(onRefresh: onRefresh!, child: listView);
          },
        ),
      ),
    ],
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const AppCard({super.key, required this.child, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(23),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF34445A).withValues(alpha: .05),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionHeading(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              action!,
              style: const TextStyle(color: AppColors.purple),
            ),
          ),
      ],
    ),
  );
}

class FeatureTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const FeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AppCard(
          color: color,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(icon, color: AppColors.purple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.purple),
            ],
          ),
        ),
      ),
    ),
  );
}

class MetricCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const MetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    color: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.purple),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}

class ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final String? detail;
  const ProgressRow(this.label, this.value, {super.key, this.detail});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            detail ?? '${(value * 100).round()}%',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          color: AppColors.purple,
          backgroundColor: AppColors.bg,
        ),
      ),
    ],
  );
}

class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.purple),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    ),
  );
}

class AppError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => AppCard(
    color: const Color(0xFFFFEEEE),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Color(0xFFB54747))),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tekrar dene'),
        ),
      ],
    ),
  );
}

void openPage(BuildContext context, Widget page) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: page),
    ),
  ),
);
