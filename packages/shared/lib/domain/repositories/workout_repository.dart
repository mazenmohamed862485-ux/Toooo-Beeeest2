// ============================================================
// TO Best — domain/repositories/workout_repository.dart
// ============================================================

import '../entities/workout_session.dart';

abstract class WorkoutRepository {
  /// جلب جلسات التمرين لمستخدم في فترة معينة
  Future<List<WorkoutSession>> getWorkoutSessions({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  /// حفظ/تحديث جلسة تمرين
  Future<void> saveWorkoutSession(WorkoutSession session);

  /// جلب تاريخ تمرين معين (لحساب Evaluator)
  Future<List<WorkoutSession>> getExerciseHistory({
    required String userId,
    required String exerciseName,
    int limit,
  });

  /// جلب تعريفات التمارين للجلسة المحددة
  Future<List<ExerciseDefinition>> getSessionExercises({
    required String programId,
    required String sessionName,
    required String userId,
  });

  /// حفظ طلب تغيير برنامج
  Future<void> saveProgramChangeRequest(ProgramChangeRequest request);

  /// مزامنة مع GAS
  Future<void> syncWorkoutsToRemote(String userId);

  /// جلب الـ Streak الحالي
  Future<int> getCurrentStreak(String userId);

  /// جلب Heatmap بيانات (شهر كامل)
  Future<Map<DateTime, bool>> getMonthlyActivity({
    required String userId,
    required int year,
    required int month,
  });
}

// ============================================================
// nutrition_repository.dart
// ============================================================

import '../entities/nutrition.dart';

abstract class NutritionRepository {
  /// جلب ملخص التغذية ليوم معين
  Future<DailyNutritionSummary> getDailyNutrition({
    required String userId,
    required DateTime date,
  });

  /// حفظ وجبة
  Future<void> saveMealLog(MealLog meal);

  /// البحث في قاعدة الأطعمة (Isar)
  Future<List<FoodItem>> searchFood(String query, {int limit = 12});

  /// جلب كل قاعدة الأطعمة (للـ parseMealText)
  Future<List<FoodItem>> getAllFoods();

  /// بذر قاعدة الأطعمة في Isar (يُنفَّذ مرة واحدة)
  Future<void> seedFoodDatabase();

  /// مزامنة التغذية مع GAS
  Future<void> syncNutritionToRemote(String userId);
}

// ============================================================
// chat_repository.dart
// ============================================================

import '../entities/chat_message.dart';

abstract class ChatRepository {
  /// جلب المحادثات للمستخدم الحالي
  Future<List<Conversation>> getConversations(String userId);

  /// جلب رسائل محادثة
  Future<List<ChatMessage>> getMessages({
    required String roomId,
    DateTime? since,
    int limit,
  });

  /// إرسال رسالة
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required String messageType,
    String? replyToId,
    String? mediaUrl,
  });

  /// تعديل رسالة
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newContent,
  });

  /// حذف رسالة
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  });

  /// تأشير كقروء
  Future<void> markAsRead({
    required String roomId,
    required String userId,
  });

  /// إضافة تفاعل على رسالة
  Future<void> addReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String reactionCode,
  });

  /// حفظ رسالة AI محلياً ومزامنتها
  Future<void> saveAiMessage(AiMessage message);

  /// جلب سجل AI
  Future<List<AiMessage>> getAiHistory(String userId);

  /// مسح سجل AI
  Future<void> clearAiHistory(String userId);
}

// ============================================================
// health_repository.dart
// ============================================================

import '../entities/health_data.dart';

abstract class HealthRepository {
  /// جلب بيانات الصحة ليوم معين
  Future<HealthData?> getHealthData({
    required String userId,
    required DateTime date,
  });

  /// حفظ بيانات الصحة
  Future<void> saveHealthData(HealthData data);

  /// تحديث بيانات الخطوات
  Future<void> updateSteps({
    required String userId,
    required DateTime date,
    required int steps,
    required double distanceKm,
    required double burnedCalories,
  });

  /// حفظ بيانات النوم
  Future<void> saveSleepData({
    required String userId,
    required DateTime date,
    required SleepData sleep,
  });

  /// جلب هدف المشي
  Future<WalkingGoal> getWalkingGoal(String userId);

  /// حفظ هدف المشي
  Future<void> saveWalkingGoal({
    required String userId,
    required WalkingGoal goal,
  });

  /// مزامنة مع GAS
  Future<void> syncHealthToRemote(String userId);
}

// ============================================================
// subscription_repository.dart
// ============================================================

import '../entities/health_data.dart';

abstract class SubscriptionRepository {
  /// رفع طلب اشتراك
  Future<void> submitSubscriptionRequest({
    required String userId,
    required String planType,
    required String paymentProofBase64,
  });

  /// جلب الخطط المتاحة (ديناميكية من GAS)
  Future<List<SubscriptionPlan>> getAvailablePlans();

  /// جلب طلبات الاشتراك (Management)
  Future<List<SubscriptionRequest>> getSubscriptionRequests({
    String status,
  });

  /// الموافقة على طلب
  Future<void> approveRequest({
    required String requestId,
    required DateTime startDate,
    required String processedBy,
  });

  /// رفض طلب
  Future<void> rejectRequest({
    required String requestId,
    required String reason,
    required String processedBy,
  });
}

// الـ import هنا من health_data.dart تم خطأً — تصحيح:
// ignore: unused_import
import '../entities/health_data.dart' as _health;
import '../entities/health_data.dart'
    show SubscriptionPlan, SubscriptionRequest;

// ============================================================
// video_repository.dart
// ============================================================

import '../entities/health_data.dart' show VideoMetadata;

abstract class VideoRepository {
  /// جلب metadata الفيديوهات لتمرين معين
  Future<List<VideoMetadata>> getVideosForExercise(String exerciseId);

  /// الحصول على Streaming URL
  Future<String> getStreamUrl(String videoId);

  /// Pre-fetch فيديو في الكاش
  Future<void> prefetchVideo(String videoId);

  /// هل الفيديو محفوظ في الكاش
  Future<bool> isVideoCached(String videoId);

  /// مسح كاش الفيديو
  Future<void> clearVideoCache();

  /// حجم الكاش الحالي بالـ Bytes
  Future<int> getCacheSize();
}
