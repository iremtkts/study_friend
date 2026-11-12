import 'package:flutter_test/flutter_test.dart';
import 'package:study_friend/models/api_models.dart';

void main() {
  test('QuizStatsOut converts dynamic lists to typed stat models', () {
    final stats = QuizStatsOut.fromJson({
      'total_attempts': 1,
      'average_score': '80',
      'highest_score': '80',
      'recent_attempts': [
        {
          'attempted_at': '2026-11-12T09:00:00Z',
          'quiz_title': 'Matematik',
          'score_percent': '80',
        },
      ],
      'categories': [
        {
          'category_id': 'category-id',
          'category_name': 'Matematik',
          'attempt_count': 1,
          'average_score': '80',
        },
      ],
    });

    expect(stats.recentAttempts.single, isA<RecentAttemptStat>());
    expect(stats.categories.single, isA<CategoryStatsOut>());
    expect(stats.categories.single.averageScore, 80);
  });
}
