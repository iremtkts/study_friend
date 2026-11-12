import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/app_widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});
  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Üyelik planı',
    subtitle: 'Öğrenme alışkanlığına uygun planı seç.',
    children: [
      AppCard(
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FREE',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Temel çalışma araçları',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ders kütüphanesi, çalışma programı ve temel ilerleme görünümü.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
      AppCard(
        color: const Color(0xFFE5DCFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: AppColors.purple),
                SizedBox(width: 8),
                Text(
                  'PLUS',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Daha fazlasını keşfet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gelişmiş AI çalışma araçları, daha fazla quiz ve kişisel öğrenme içgörüleri.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plus planı tasarım önizlemesidir.'),
                ),
              ),
              style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
              child: const Text('Plus’ı keşfet'),
            ),
          ],
        ),
      ),
    ],
  );
}
