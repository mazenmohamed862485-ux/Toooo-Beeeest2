// TO Best — infrastructure/isar_service.dart

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/user_model.dart';
import '../data/models/workout_model.dart';
import '../data/models/food_model.dart';
import '../data/models/chat_model.dart';
import '../data/models/health_model.dart';
import '../data/models/subscription_model.dart';

part 'isar_service.g.dart';

class IsarService {
  IsarService._internal();
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;

  Isar? _isar;

  Future<Isar> get db async {
    _isar ??= await _openIsar();
    return _isar!;
  }

  bool get isOpen => _isar?.isOpen ?? false;

  Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        UserIsarModelSchema,
        WorkoutSessionIsarModelSchema,
        ExerciseLogIsarModelSchema,
        FoodItemIsarModelSchema,
        MealLogIsarModelSchema,
        ChatMessageIsarModelSchema,
        AiMessageIsarModelSchema,
        HealthDataIsarModelSchema,
        SubscriptionRequestIsarModelSchema,
        SyncQueueItemSchema,
        AppSettingsIsarModelSchema,
      ],
      directory: dir.path,
      name: 'tobest_db',
    );
  }

  Future<void> clearAll() async {
    final db = await this.db;
    await db.writeTxn(() async {
      await db.userIsarModels.clear();
      await db.workoutSessionIsarModels.clear();
      await db.exerciseLogIsarModels.clear();
      await db.foodItemIsarModels.clear();
      await db.mealLogIsarModels.clear();
      await db.chatMessageIsarModels.clear();
      await db.healthDataIsarModels.clear();
      await db.subscriptionRequestIsarModels.clear();
      await db.syncQueueItems.clear();
    });
  }

  Future<void> clearUserData(String userId) async {
    final db = await this.db;
    await db.writeTxn(() async {
      await db.workoutSessionIsarModels
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
      await db.mealLogIsarModels.filter().userIdEqualTo(userId).deleteAll();
      await db.healthDataIsarModels.filter().userIdEqualTo(userId).deleteAll();
      await db.chatMessageIsarModels.filter().userIdEqualTo(userId).deleteAll();
      await db.aiMessageIsarModels.filter().userIdEqualTo(userId).deleteAll();
    });
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}

@Collection()
class SyncQueueItem {
  SyncQueueItem({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Id id = Isar.autoIncrement;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final DateTime createdAt;
  int retryCount;
}

@Collection()
class AppSettingsIsarModel {
  AppSettingsIsarModel({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String key;

  final String value;
  final DateTime updatedAt;
}
