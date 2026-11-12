String _stringFromJson(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String) {
    return value;
  }
  throw FormatException('API alanı "$field" geçerli bir metin değil.');
}

String? _nullableStringFromJson(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null || value is String) {
    return value as String?;
  }
  throw FormatException('API alanı "$field" geçerli bir metin değil.');
}

bool _boolFromJson(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is bool) {
    return value;
  }
  throw FormatException('API alanı "$field" geçerli bir boolean değil.');
}

int? _nullableIntFromJson(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null || value is int) {
    return value as int?;
  }
  throw FormatException('API alanı "$field" geçerli bir tam sayı değil.');
}

Map<String, dynamic> _mapFromJson(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map && value.keys.every((key) => key is String)) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('API alanı "$field" geçerli bir nesne değil.');
}

DateTime _dateTimeFromJson(Object? value, String field) {
  if (value is! String) {
    throw FormatException('API alanı "$field" geçerli bir tarih değil.');
  }
  return DateTime.parse(value);
}

DateTime? _nullableDateTimeFromJson(Object? value, String field) =>
    value == null ? null : _dateTimeFromJson(value, field);

double _doubleFromJson(Object? value, String field) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('API alanı "$field" geçerli bir sayı değil.');
}

class UserPublic {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime? emailVerifiedAt;

  const UserPublic({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.emailVerifiedAt,
  });

  factory UserPublic.fromJson(Map<String, dynamic> json) => UserPublic(
    id: _stringFromJson(json, 'id'),
    email: _stringFromJson(json, 'email'),
    fullName: _nullableStringFromJson(json, 'full_name'),
    role: _stringFromJson(json, 'role'),
    isActive: _boolFromJson(json, 'is_active'),
    emailVerifiedAt: _nullableDateTimeFromJson(
      json['email_verified_at'],
      'email_verified_at',
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'is_active': isActive,
    'email_verified_at': emailVerifiedAt?.toIso8601String(),
  };
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserPublic user;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final tokenType = _nullableStringFromJson(json, 'token_type');
    return TokenPair(
      accessToken: _stringFromJson(json, 'access_token'),
      refreshToken: _stringFromJson(json, 'refresh_token'),
      tokenType: tokenType ?? 'bearer',
      user: UserPublic.fromJson(_mapFromJson(json['user'], 'user')),
    );
  }
}

class RegistrationResponse {
  final UserPublic user;
  final String message;

  const RegistrationResponse({required this.user, required this.message});

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) =>
      RegistrationResponse(
        user: UserPublic.fromJson(_mapFromJson(json['user'], 'user')),
        message: _stringFromJson(json, 'message'),
      );
}

class MessageResponse {
  final String message;

  const MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      MessageResponse(message: _stringFromJson(json, 'message'));
}

class AIJobOut {
  final String jobId;
  final String? conversationId;
  final String? resultId;
  final String status;
  final String? errorCode;
  final int? resultCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const AIJobOut({
    required this.jobId,
    required this.conversationId,
    required this.resultId,
    required this.status,
    required this.errorCode,
    required this.resultCount,
    required this.createdAt,
    required this.startedAt,
    required this.finishedAt,
  });

  factory AIJobOut.fromJson(Map<String, dynamic> json) {
    final resultCount = _nullableIntFromJson(json, 'result_count');
    return AIJobOut(
      jobId: _stringFromJson(json, 'job_id'),
      conversationId: _nullableStringFromJson(json, 'conversation_id'),
      resultId: _nullableStringFromJson(json, 'result_id'),
      status: _stringFromJson(json, 'status'),
      errorCode: _nullableStringFromJson(json, 'error_code'),
      resultCount: resultCount,
      createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
      startedAt: _nullableDateTimeFromJson(json['started_at'], 'started_at'),
      finishedAt: _nullableDateTimeFromJson(json['finished_at'], 'finished_at'),
    );
  }
}

class AttemptListItemOut {
  final String id;
  final String quizId;
  final String quizTitle;
  final double scorePercent;
  final DateTime completedAt;

  const AttemptListItemOut({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.scorePercent,
    required this.completedAt,
  });

  factory AttemptListItemOut.fromJson(Map<String, dynamic> json) =>
      AttemptListItemOut(
        id: _stringFromJson(json, 'id'),
        quizId: _stringFromJson(json, 'quiz_id'),
        quizTitle: _stringFromJson(json, 'quiz_title'),
        scorePercent: _doubleFromJson(json['score_percent'], 'score_percent'),
        completedAt: _dateTimeFromJson(json['completed_at'], 'completed_at'),
      );
}

class RecentAttemptStat {
  final DateTime attemptedAt;
  final String quizTitle;
  final double scorePercent;

  const RecentAttemptStat({
    required this.attemptedAt,
    required this.quizTitle,
    required this.scorePercent,
  });

  factory RecentAttemptStat.fromJson(Map<String, dynamic> json) =>
      RecentAttemptStat(
        attemptedAt: _dateTimeFromJson(json['attempted_at'], 'attempted_at'),
        quizTitle: _stringFromJson(json, 'quiz_title'),
        scorePercent: _doubleFromJson(json['score_percent'], 'score_percent'),
      );
}

class CategoryStatsOut {
  final String categoryId;
  final String categoryName;
  final int attemptCount;
  final double? averageScore;

  const CategoryStatsOut({
    required this.categoryId,
    required this.categoryName,
    required this.attemptCount,
    required this.averageScore,
  });

  factory CategoryStatsOut.fromJson(Map<String, dynamic> json) =>
      CategoryStatsOut(
        categoryId: _stringFromJson(json, 'category_id'),
        categoryName: _stringFromJson(json, 'category_name'),
        attemptCount: _intFromJson(json, 'attempt_count'),
        averageScore: json['average_score'] == null
            ? null
            : _doubleFromJson(json['average_score'], 'average_score'),
      );
}

class QuizStatsOut {
  final int totalAttempts;
  final double? averageScore;
  final double? highestScore;
  final List<RecentAttemptStat> recentAttempts;
  final List<CategoryStatsOut> categories;

  const QuizStatsOut({
    required this.totalAttempts,
    required this.averageScore,
    required this.highestScore,
    required this.recentAttempts,
    required this.categories,
  });

  factory QuizStatsOut.fromJson(Map<String, dynamic> json) {
    final recent = json['recent_attempts'];
    final categories = json['categories'];
    if (recent is! List || (categories != null && categories is! List)) {
      throw const FormatException('Test istatistikleri geçersiz.');
    }
    final recentAttempts = <RecentAttemptStat>[
      for (final item in recent)
        RecentAttemptStat.fromJson(_mapFromJson(item, 'recent_attempts')),
    ];
    final categoryStats = <CategoryStatsOut>[
      if (categories != null)
        for (final item in categories)
          CategoryStatsOut.fromJson(_mapFromJson(item, 'categories')),
    ];
    return QuizStatsOut(
      totalAttempts: _intFromJson(json, 'total_attempts'),
      averageScore: json['average_score'] == null
          ? null
          : _doubleFromJson(json['average_score'], 'average_score'),
      highestScore: json['highest_score'] == null
          ? null
          : _doubleFromJson(json['highest_score'], 'highest_score'),
      recentAttempts: recentAttempts,
      categories: categoryStats,
    );
  }
}

class CategoryOut {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryOut({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryOut.fromJson(Map<String, dynamic> json) => CategoryOut(
    id: _stringFromJson(json, 'id'),
    name: _stringFromJson(json, 'name'),
    createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
    updatedAt: _dateTimeFromJson(json['updated_at'], 'updated_at'),
  );
}

class NoteListOut {
  final String id;
  final String categoryId;
  final String? title;
  final String originalFilename;
  final String fileType;
  final int fileSizeBytes;
  final String indexStatus;
  final DateTime createdAt;

  const NoteListOut({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.originalFilename,
    required this.fileType,
    required this.fileSizeBytes,
    required this.indexStatus,
    required this.createdAt,
  });

  factory NoteListOut.fromJson(Map<String, dynamic> json) => NoteListOut(
    id: _stringFromJson(json, 'id'),
    categoryId: _stringFromJson(json, 'category_id'),
    title: _nullableStringFromJson(json, 'title'),
    originalFilename: _stringFromJson(json, 'original_filename'),
    fileType: _stringFromJson(json, 'file_type'),
    fileSizeBytes: _intFromJson(json, 'file_size_bytes'),
    indexStatus: _stringFromJson(json, 'index_status'),
    createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
  );

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title! : originalFilename;
}

class NoteDetailOut extends NoteListOut {
  final String extractedText;

  const NoteDetailOut({
    required super.id,
    required super.categoryId,
    required super.title,
    required super.originalFilename,
    required super.fileType,
    required super.fileSizeBytes,
    required super.indexStatus,
    required super.createdAt,
    required this.extractedText,
  });

  factory NoteDetailOut.fromJson(Map<String, dynamic> json) => NoteDetailOut(
    id: _stringFromJson(json, 'id'),
    categoryId: _stringFromJson(json, 'category_id'),
    title: _nullableStringFromJson(json, 'title'),
    originalFilename: _stringFromJson(json, 'original_filename'),
    fileType: _stringFromJson(json, 'file_type'),
    fileSizeBytes: _intFromJson(json, 'file_size_bytes'),
    indexStatus: _stringFromJson(json, 'index_status'),
    createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
    extractedText: _stringFromJson(json, 'extracted_text'),
  );
}

class ConversationOut {
  final String id;
  final String categoryId;
  final String? noteId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationOut({
    required this.id,
    required this.categoryId,
    required this.noteId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationOut.fromJson(Map<String, dynamic> json) =>
      ConversationOut(
        id: _stringFromJson(json, 'id'),
        categoryId: _stringFromJson(json, 'category_id'),
        noteId: _nullableStringFromJson(json, 'note_id'),
        title: _nullableStringFromJson(json, 'title'),
        createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
        updatedAt: _dateTimeFromJson(json['updated_at'], 'updated_at'),
      );
}

class ConversationMessageOut {
  final String id;
  final String role;
  final String content;
  final List<String> sources;
  final String? modelName;
  final DateTime createdAt;

  const ConversationMessageOut({
    required this.id,
    required this.role,
    required this.content,
    required this.sources,
    required this.modelName,
    required this.createdAt,
  });

  factory ConversationMessageOut.fromJson(Map<String, dynamic> json) {
    final sources = json['sources'];
    if (sources != null &&
        (sources is! List || sources.any((source) => source is! String))) {
      throw const FormatException('Mesaj kaynakları geçersiz.');
    }
    return ConversationMessageOut(
      id: _stringFromJson(json, 'id'),
      role: _stringFromJson(json, 'role'),
      content: _stringFromJson(json, 'content'),
      sources: sources == null ? const [] : sources.cast<String>(),
      modelName: _nullableStringFromJson(json, 'model_name'),
      createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
    );
  }
}

class ConversationDetailOut extends ConversationOut {
  final List<ConversationMessageOut> messages;
  final int messagesLimit;
  final int messagesOffset;

  const ConversationDetailOut({
    required super.id,
    required super.categoryId,
    required super.noteId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required this.messages,
    required this.messagesLimit,
    required this.messagesOffset,
  });

  factory ConversationDetailOut.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'];
    if (messages is! List) {
      throw const FormatException('Sohbet mesajları geçersiz.');
    }
    return ConversationDetailOut(
      id: _stringFromJson(json, 'id'),
      categoryId: _stringFromJson(json, 'category_id'),
      noteId: _nullableStringFromJson(json, 'note_id'),
      title: _nullableStringFromJson(json, 'title'),
      createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
      updatedAt: _dateTimeFromJson(json['updated_at'], 'updated_at'),
      messages: messages
          .map(
            (item) =>
                ConversationMessageOut.fromJson(_mapFromJson(item, 'messages')),
          )
          .toList(),
      messagesLimit: _intFromJson(json, 'messages_limit'),
      messagesOffset: _intFromJson(json, 'messages_offset'),
    );
  }
}

class ChatJobOut {
  final String jobId;
  final String status;
  final String messageId;

  const ChatJobOut({
    required this.jobId,
    required this.status,
    required this.messageId,
  });

  factory ChatJobOut.fromJson(Map<String, dynamic> json) => ChatJobOut(
    jobId: _stringFromJson(json, 'job_id'),
    status: _stringFromJson(json, 'status'),
    messageId: _stringFromJson(json, 'message_id'),
  );
}

class SummaryOut {
  final String id;
  final String noteId;
  final String content;
  final int position;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SummaryOut({
    required this.id,
    required this.noteId,
    required this.content,
    required this.position,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SummaryOut.fromJson(Map<String, dynamic> json) => SummaryOut(
    id: _stringFromJson(json, 'id'),
    noteId: _stringFromJson(json, 'note_id'),
    content: _stringFromJson(json, 'content'),
    position: _intFromJson(json, 'position'),
    source: _stringFromJson(json, 'source'),
    createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
    updatedAt: _dateTimeFromJson(json['updated_at'], 'updated_at'),
  );
}

class QuizQuestionPublicOut {
  final String id;
  final int position;
  final String questionText;
  final List<String> options;
  final DateTime createdAt;

  const QuizQuestionPublicOut({
    required this.id,
    required this.position,
    required this.questionText,
    required this.options,
    required this.createdAt,
  });

  factory QuizQuestionPublicOut.fromJson(Map<String, dynamic> json) {
    final optionsValue = json['options'];
    if (optionsValue is! List || optionsValue.any((item) => item is! String)) {
      throw const FormatException('Quiz seçenekleri geçersiz.');
    }
    return QuizQuestionPublicOut(
      id: _stringFromJson(json, 'id'),
      position: _intFromJson(json, 'position'),
      questionText: _stringFromJson(json, 'question_text'),
      options: optionsValue.cast<String>(),
      createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
    );
  }
}

class QuizListOut {
  final String id;
  final String categoryId;
  final String? noteId;
  final String title;
  final String source;
  final DateTime createdAt;
  final int questionCount;

  const QuizListOut({
    required this.id,
    required this.categoryId,
    required this.noteId,
    required this.title,
    required this.source,
    required this.createdAt,
    required this.questionCount,
  });

  factory QuizListOut.fromJson(Map<String, dynamic> json) => QuizListOut(
    id: _stringFromJson(json, 'id'),
    categoryId: _stringFromJson(json, 'category_id'),
    noteId: _nullableStringFromJson(json, 'note_id'),
    title: _stringFromJson(json, 'title'),
    source: _stringFromJson(json, 'source'),
    createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
    questionCount: _intFromJson(json, 'question_count'),
  );
}

class QuizDetailOut {
  final String id;
  final String categoryId;
  final String? noteId;
  final String title;
  final String source;
  final DateTime createdAt;
  final List<QuizQuestionPublicOut> questions;

  const QuizDetailOut({
    required this.id,
    required this.categoryId,
    required this.noteId,
    required this.title,
    required this.source,
    required this.createdAt,
    required this.questions,
  });

  factory QuizDetailOut.fromJson(Map<String, dynamic> json) {
    final questionValues = json['questions'];
    if (questionValues is! List) {
      throw const FormatException('Quiz soruları geçersiz.');
    }
    return QuizDetailOut(
      id: _stringFromJson(json, 'id'),
      categoryId: _stringFromJson(json, 'category_id'),
      noteId: _nullableStringFromJson(json, 'note_id'),
      title: _stringFromJson(json, 'title'),
      source: _stringFromJson(json, 'source'),
      createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
      questions: questionValues
          .map(
            (item) =>
                QuizQuestionPublicOut.fromJson(_mapFromJson(item, 'questions')),
          )
          .toList(),
    );
  }
}

class AttemptInProgressOut {
  final String id;
  final String quizId;
  final String status;
  final DateTime startedAt;

  const AttemptInProgressOut({
    required this.id,
    required this.quizId,
    required this.status,
    required this.startedAt,
  });

  factory AttemptInProgressOut.fromJson(Map<String, dynamic> json) =>
      AttemptInProgressOut(
        id: _stringFromJson(json, 'id'),
        quizId: _stringFromJson(json, 'quiz_id'),
        status: _stringFromJson(json, 'status'),
        startedAt: _dateTimeFromJson(json['started_at'], 'started_at'),
      );
}

class AttemptQuestionResultOut {
  final String questionId;
  final String questionText;
  final int? selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String? explanation;

  const AttemptQuestionResultOut({
    required this.questionId,
    required this.questionText,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  factory AttemptQuestionResultOut.fromJson(Map<String, dynamic> json) =>
      AttemptQuestionResultOut(
        questionId: _stringFromJson(json, 'question_id'),
        questionText: _stringFromJson(json, 'question_text'),
        selectedIndex: _nullableIntFromJson(json, 'selected_index'),
        correctIndex: _intFromJson(json, 'correct_index'),
        isCorrect: _boolFromJson(json, 'is_correct'),
        explanation: _nullableStringFromJson(json, 'explanation'),
      );
}

class AttemptCompletedOut {
  final String id;
  final String quizId;
  final String status;
  final DateTime startedAt;
  final DateTime completedAt;
  final int correctCount;
  final int totalQuestions;
  final double scorePercent;
  final List<AttemptQuestionResultOut> answers;

  const AttemptCompletedOut({
    required this.id,
    required this.quizId,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.correctCount,
    required this.totalQuestions,
    required this.scorePercent,
    required this.answers,
  });

  factory AttemptCompletedOut.fromJson(Map<String, dynamic> json) {
    final answers = json['answers'];
    if (answers is! List) {
      throw const FormatException('Deneme yanıtları geçersiz.');
    }
    return AttemptCompletedOut(
      id: _stringFromJson(json, 'id'),
      quizId: _stringFromJson(json, 'quiz_id'),
      status: _stringFromJson(json, 'status'),
      startedAt: _dateTimeFromJson(json['started_at'], 'started_at'),
      completedAt: _dateTimeFromJson(json['completed_at'], 'completed_at'),
      correctCount: _intFromJson(json, 'correct_count'),
      totalQuestions: _intFromJson(json, 'total_questions'),
      scorePercent: _doubleFromJson(json['score_percent'], 'score_percent'),
      answers: answers
          .map(
            (item) => AttemptQuestionResultOut.fromJson(
              _mapFromJson(item, 'answers'),
            ),
          )
          .toList(),
    );
  }
}

class RelatedSummaryOut {
  final String id;
  final String content;

  const RelatedSummaryOut({required this.id, required this.content});

  factory RelatedSummaryOut.fromJson(Map<String, dynamic> json) =>
      RelatedSummaryOut(
        id: _stringFromJson(json, 'id'),
        content: _stringFromJson(json, 'content'),
      );
}

class WeakTopicOut {
  final String questionId;
  final String questionText;
  final String? selectedOptionText;
  final String correctOptionText;
  final String? explanation;
  final List<RelatedSummaryOut> relatedSummaries;

  const WeakTopicOut({
    required this.questionId,
    required this.questionText,
    required this.selectedOptionText,
    required this.correctOptionText,
    required this.explanation,
    required this.relatedSummaries,
  });

  factory WeakTopicOut.fromJson(Map<String, dynamic> json) {
    final related = json['related_summaries'];
    if (related is! List) {
      throw const FormatException('İlgili özet kartları geçersiz.');
    }
    return WeakTopicOut(
      questionId: _stringFromJson(json, 'question_id'),
      questionText: _stringFromJson(json, 'question_text'),
      selectedOptionText: _nullableStringFromJson(json, 'selected_option_text'),
      correctOptionText: _stringFromJson(json, 'correct_option_text'),
      explanation: _nullableStringFromJson(json, 'explanation'),
      relatedSummaries: related
          .map(
            (item) => RelatedSummaryOut.fromJson(
              _mapFromJson(item, 'related_summaries'),
            ),
          )
          .toList(),
    );
  }
}

class SuggestedPlanItem {
  final Map<String, dynamic> json;
  final int dayOfWeek;
  final String? startTime;
  final int? durationMinutes;
  final String topic;
  final String? categoryId;
  final String? noteId;

  const SuggestedPlanItem({
    required this.json,
    required this.dayOfWeek,
    required this.startTime,
    required this.durationMinutes,
    required this.topic,
    required this.categoryId,
    required this.noteId,
  });

  factory SuggestedPlanItem.fromJson(Map<String, dynamic> json) =>
      SuggestedPlanItem(
        json: Map<String, dynamic>.unmodifiable(json),
        dayOfWeek: _intFromJson(json, 'day_of_week'),
        startTime: _nullableStringFromJson(json, 'start_time'),
        durationMinutes: _nullableIntFromJson(json, 'duration_minutes'),
        topic: _stringFromJson(json, 'topic'),
        categoryId: _nullableStringFromJson(json, 'category_id'),
        noteId: _nullableStringFromJson(json, 'note_id'),
      );

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(json);
}

class SuggestedPlanOut {
  final String weekStart;
  final List<SuggestedPlanItem> items;

  const SuggestedPlanOut({required this.weekStart, required this.items});

  factory SuggestedPlanOut.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Önerilen çalışma maddeleri geçersiz.');
    }
    return SuggestedPlanOut(
      weekStart: _stringFromJson(json, 'week_start'),
      items: items
          .map(
            (item) => SuggestedPlanItem.fromJson(
              _mapFromJson(item, 'suggested_plan.items'),
            ),
          )
          .toList(),
    );
  }
}

class AttemptRecommendationOut {
  final String message;
  final List<WeakTopicOut> weakTopics;
  final SuggestedPlanOut suggestedPlan;

  const AttemptRecommendationOut({
    required this.message,
    required this.weakTopics,
    required this.suggestedPlan,
  });

  factory AttemptRecommendationOut.fromJson(Map<String, dynamic> json) {
    final topics = json['weak_topics'];
    if (topics is! List) {
      throw const FormatException('Zayıf konu önerileri geçersiz.');
    }
    return AttemptRecommendationOut(
      message: _stringFromJson(json, 'message'),
      weakTopics: topics
          .map(
            (item) => WeakTopicOut.fromJson(_mapFromJson(item, 'weak_topics')),
          )
          .toList(),
      suggestedPlan: SuggestedPlanOut.fromJson(
        _mapFromJson(json['suggested_plan'], 'suggested_plan'),
      ),
    );
  }
}

class StudyPlanOut {
  final String id;
  final String weekStart;
  final String? title;

  const StudyPlanOut({
    required this.id,
    required this.weekStart,
    required this.title,
  });

  factory StudyPlanOut.fromJson(Map<String, dynamic> json) => StudyPlanOut(
    id: _stringFromJson(json, 'id'),
    weekStart: _stringFromJson(json, 'week_start'),
    title: _nullableStringFromJson(json, 'title'),
  );
}

class StudyPlanItemOut extends SuggestedPlanItem {
  final String id;
  final String planId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyPlanItemOut({
    required super.json,
    required super.dayOfWeek,
    required super.startTime,
    required super.durationMinutes,
    required super.topic,
    required super.categoryId,
    required super.noteId,
    required this.id,
    required this.planId,
    required this.isCompleted,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudyPlanItemOut.fromJson(Map<String, dynamic> json) =>
      StudyPlanItemOut(
        json: Map<String, dynamic>.unmodifiable(json),
        dayOfWeek: _intFromJson(json, 'day_of_week'),
        startTime: _nullableStringFromJson(json, 'start_time'),
        durationMinutes: _nullableIntFromJson(json, 'duration_minutes'),
        topic: _stringFromJson(json, 'topic'),
        categoryId: _nullableStringFromJson(json, 'category_id'),
        noteId: _nullableStringFromJson(json, 'note_id'),
        id: _stringFromJson(json, 'id'),
        planId: _stringFromJson(json, 'plan_id'),
        isCompleted: _boolFromJson(json, 'is_completed'),
        completedAt: _nullableDateTimeFromJson(
          json['completed_at'],
          'completed_at',
        ),
        createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
        updatedAt: _dateTimeFromJson(json['updated_at'], 'updated_at'),
      );
}

class StudyPlanProgressOut {
  final int totalItems;
  final int completedItems;
  final double progressPercent;

  const StudyPlanProgressOut({
    required this.totalItems,
    required this.completedItems,
    required this.progressPercent,
  });

  factory StudyPlanProgressOut.fromJson(Map<String, dynamic> json) =>
      StudyPlanProgressOut(
        totalItems: _intFromJson(json, 'total_items'),
        completedItems: _intFromJson(json, 'completed_items'),
        progressPercent: _doubleFromJson(
          json['progress_percent'],
          'progress_percent',
        ),
      );
}

class StudyPlanDetailOut extends StudyPlanOut {
  final List<StudyPlanItemOut> items;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StudyPlanProgressOut progress;

  const StudyPlanDetailOut({
    required super.id,
    required super.weekStart,
    required super.title,
    required this.items,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.progress,
  });

  factory StudyPlanDetailOut.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Program maddeleri geçersiz.');
    }
    return StudyPlanDetailOut(
      id: _stringFromJson(json, 'id'),
      weekStart: _stringFromJson(json, 'week_start'),
      title: _nullableStringFromJson(json, 'title'),
      source: _stringFromJson(json, 'source'),
      createdAt: _dateTimeFromJson(json['created_at'], 'created_at'),
      updatedAt: _dateTimeFromJson(json['updated_at'], 'updated_at'),
      items: items
          .map((item) => StudyPlanItemOut.fromJson(_mapFromJson(item, 'items')))
          .toList(),
      progress: StudyPlanProgressOut.fromJson(
        _mapFromJson(json['progress'], 'progress'),
      ),
    );
  }
}

int _intFromJson(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is int) {
    return value;
  }
  throw FormatException('API alanı "$field" geçerli bir tam sayı değil.');
}
