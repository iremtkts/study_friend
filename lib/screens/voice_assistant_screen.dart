import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'tutor_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});
  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool listening = false;
  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Fiko ile sesli konuş',
    subtitle: 'Fiko’yla konuşarak çalış.',
    children: [
      const SizedBox(height: 35),
      Center(
        child: Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFCDBBFA).withValues(alpha: .55),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: .15),
                blurRadius: 35,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'Winking Fox Study Mascot.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Center(
        child: Text(
          listening ? 'Fiko seni dinliyor…' : 'Fiko’yla konuşmaya hazır mısın?',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 8),
      const Center(
        child: Text(
          'Sesli çalışma deneyimi',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      const SizedBox(height: 28),
      FilledButton.icon(
        onPressed: () => setState(() => listening = !listening),
        icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
        label: Text(listening ? 'Konuşmayı bitir' : 'Fiko ile konuşmaya başla'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.purple,
          minimumSize: const Size.fromHeight(54),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => openPage(context, const TutorScreen()),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Fiko ile yazılı sohbet et'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: AppColors.purple,
        ),
      ),
    ],
  );
}
