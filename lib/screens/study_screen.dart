import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';
import 'library_screen.dart';
import 'cards_screen.dart';
import 'schedule_screen.dart';
import 'quiz_screen.dart';
import 'voice_assistant_screen.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Çalışma alanın',
    subtitle: 'Bugün hangi konuda ilerleyelim?',
    children: [
      FeatureTile(
        title: 'PDF kütüphanesi',
        subtitle: 'Ders materyallerini keşfet',
        icon: Icons.folder_copy_rounded,
        color: const Color(0xFFE5DCFC),
        onTap: () => openPage(context, const LibraryScreen()),
      ),
      FeatureTile(
        title: 'Çalışma kartları',
        subtitle: 'Kartlarla bilgini pekiştir',
        icon: Icons.style_rounded,
        color: const Color(0xFFDDEFFA),
        onTap: () => openPage(context, const CardsScreen()),
      ),
      FeatureTile(
        title: 'Haftalık program',
        subtitle: 'Çalışma oturumlarını görüntüle',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFFCEBD9),
        onTap: () => openPage(context, const ScheduleScreen()),
      ),
      FeatureTile(
        title: 'Quiz',
        subtitle: 'Kendini kısa bir test et',
        icon: Icons.quiz_rounded,
        color: const Color(0xFFE1F2EA),
        onTap: () => openPage(context, const QuizScreen()),
      ),
      FeatureTile(
        title: 'Fiko ile sesli konuş',
        subtitle: 'Fiko’yla konuşarak çalışmaya başla',
        icon: Icons.graphic_eq_rounded,
        color: const Color(0xFFE5DCFC),
        onTap: () => openPage(context, const VoiceAssistantScreen()),
      ),
    ],
  );
}
