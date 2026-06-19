// ============================================================
// TO Best — nutrition/presentation/providers/nutrition_provider.dart
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/domain/entities/nutrition.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/data/models/food_model.dart';
import 'package:shared/utils/evaluator.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import 'package:isar/isar.dart';
part 'nutrition_provider.g.dart';

// ── Daily Summary Provider ─────────────────────────────────────

@riverpod
Future<DailyNutritionSummary> dailyNutrition(
  DailyNutritionRef ref, {
  DateTime? date,
}) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return DailyNutritionSummary(
      date: date ?? DateTime.now(),
      targetCalories: 2000,
      consumedCalories: 0,
      targetProtein: 150,
      consumedProtein: 0,
      targetCarbs: 200,
      consumedCarbs: 0,
      targetFat: 65,
      consumedFat: 0,
      meals: [],
    );
  }

  final targetDate = date ?? DateTime.now();
  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  final startMs = DateTime(
    targetDate.year,
    targetDate.month,
    targetDate.day,
  ).millisecondsSinceEpoch;
  final endMs = startMs + const Duration(days: 1).inMilliseconds;

  final mealModels = await db.mealLogIsarModels
      .filter()
      .userIdEqualTo(user.uid)
      .dateMsGreaterThan(startMs - 1)
      .dateMsLessThan(endMs)
      .findAll();

  final meals = mealModels.map((m) => m.toEntity()).toList();

  double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
  for (final meal in meals) {
    totalCal += meal.totalCalories;
    totalPro += meal.totalProtein;
    totalCarb += meal.totalCarbs;
    totalFat += meal.totalFat;
  }

  // حساب الماكرو المستهدف
  final macros = Evaluator.calcMacros(
    calories: user.dailyCalories.toDouble(),
    goal: user.goal,
  );

  return DailyNutritionSummary(
    date: targetDate,
    targetCalories: user.dailyCalories.toDouble(),
    consumedCalories: totalCal,
    targetProtein: macros.protein,
    consumedProtein: totalPro,
    targetCarbs: macros.carbs,
    consumedCarbs: totalCarb,
    targetFat: macros.fat,
    consumedFat: totalFat,
    meals: meals,
  );
}

// ── Food Search Provider ───────────────────────────────────────

@riverpod
Future<List<FoodItem>> foodSearch(
  FoodSearchRef ref,
  String query,
) async {
  if (query.trim().isEmpty) return [];

  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  // بحث في Isar
  final results = await db.foodItemIsarModels
      .filter()
      .nameContains(query, caseSensitive: false)
      .limit(15)
      .findAll();

  return results.map((r) => r.toEntity()).toList();
}

// ── Meal Actions ───────────────────────────────────────────────

@riverpod
class MealActions extends _$MealActions {
  @override
  void build() {}

  Future<void> addMeal({
    required String userId,
    required String mealType,
    required List<MealItemLog> items,
    required DateTime date,
  }) async {
    final mealId = const Uuid().v4();
    final meal = MealLog(
      id: mealId,
      userId: userId,
      date: date,
      mealType: mealType,
      items: items,
      updatedAt: DateTime.now(),
    );

    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final model = MealLogIsarModel.fromEntity(meal);

    await db.writeTxn(() async {
      await db.mealLogIsarModels.put(model);
    });

    // مزامنة
    try {
      final gas = ref.read(gasClientProvider);
      await gas.post(
        action: 'SAVE_MEALS',
        data: {
          'uid': userId,
          'key': mealId,
          'data': {
            'date': date.toIso8601String().substring(0, 10),
            'mealType': mealType,
            'items': items.map((i) => {
              'id': i.foodId,
              'name': i.foodName,
              'amt': i.amount,
              'cal': i.calories,
              'pro': i.protein,
              'carb': i.carbs,
              'fat': i.fat,
            }).toList(),
          },
        },
      );
      await db.writeTxn(() async {
        model.syncedToRemote = true;
        await db.mealLogIsarModels.put(model);
      });
    } catch (_) {}

    // إعادة تحميل
    ref.invalidate(dailyNutritionProvider);
  }

  Future<void> deleteMeal(String mealId) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    await db.writeTxn(() async {
      await db.mealLogIsarModels
          .filter()
          .mealIdEqualTo(mealId)
          .deleteAll();
    });
    ref.invalidate(dailyNutritionProvider);
  }

  /// تحليل نص الوجبة الحرة
  Future<MealParseResult> parseMealText(
    String text,
    String userId,
  ) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final allFoods = await db.foodItemIsarModels.where().findAll();
    final foods = allFoods.map((f) => f.toEntity()).toList();
    return Evaluator.parseMealText(text, foods);
  }

  /// اقتراح وجبة
  Future<List<FoodItem>> suggestMeal({
    required double remainingCalories,
    required String preference,
  }) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final allFoods = await db.foodItemIsarModels.where().findAll();
    final foods = allFoods.map((f) => f.toEntity()).toList();
    return Evaluator.suggestMeal(
      remaining: remainingCalories,
      pref: preference,
      foodDb: foods,
    );
  }
}
