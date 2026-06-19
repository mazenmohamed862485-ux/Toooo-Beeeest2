// TO Best — domain/repositories/nutrition_repository.dart

import '../entities/nutrition.dart';

abstract class NutritionRepository {
  Future<DailyNutritionSummary> getDailyNutrition({
    required String userId,
    required DateTime date,
  });

  Future<void> saveMealLog(MealLog meal);
  Future<List<FoodItem>> searchFood(String query, {int limit = 12});
  Future<List<FoodItem>> getAllFoods();
  Future<void> seedFoodDatabase();
  Future<void> syncNutritionToRemote(String userId);
}
