// ============================================================
  // shared — lib/utils/evaluator.dart
  // ============================================================
  import 'package:shared/domain/entities/nutrition.dart';
  import 'package:shared/domain/entities/workout_session.dart';

  export 'package:shared/domain/entities/workout_session.dart'
      show EvalResult, RepSuggestion;

  class Evaluator {
    const Evaluator._();

    static MacroResult calcMacros({
      required double calories,
      required String goal,
    }) {
      double proteinRatio, carbsRatio, fatRatio;
      switch (goal) {
        case 'loseWeight':
          proteinRatio = 0.35; carbsRatio = 0.35; fatRatio = 0.30;
          break;
        case 'gainMuscle':
          proteinRatio = 0.30; carbsRatio = 0.45; fatRatio = 0.25;
          break;
        default:
          proteinRatio = 0.25; carbsRatio = 0.50; fatRatio = 0.25;
      }
      return MacroResult(
        calories: calories,
        protein: (calories * proteinRatio) / 4,
        carbs: (calories * carbsRatio) / 4,
        fat: (calories * fatRatio) / 9,
        fiber: 25,
      );
    }

    static MealParseResult parseMealText(String text, List<FoodItem> foods) {
      final words = text.toLowerCase().split(RegExp(r'[\s,،]+'));
      final matched = <FoodItem>[];
      final unmatched = <String>[];
      for (final word in words) {
        if (word.length < 2) continue;
        final food = foods.firstWhere(
          (f) =>
              f.name.toLowerCase().contains(word) ||
              f.nameEn.toLowerCase().contains(word) ||
              f.aliases.any((a) => a.toLowerCase().contains(word)),
          orElse: () => const FoodItem(
            id: '', name: '', nameEn: '', category: '',
            amount: 100, calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0,
          ),
        );
        if (food.id.isNotEmpty) { matched.add(food); } else { unmatched.add(word); }
      }
      double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0, totalFiber = 0;
      for (final item in matched) {
        final ratio = 100 / (item.amount > 0 ? item.amount : 100);
        totalCal += item.calories * ratio;
        totalPro += item.protein * ratio;
        totalCarb += item.carbs * ratio;
        totalFat += item.fat * ratio;
        totalFiber += item.fiber * ratio;
      }
      return MealParseResult(
        calories: totalCal, protein: totalPro, carbs: totalCarb,
        fat: totalFat, fiber: totalFiber, items: matched, unmatched: unmatched,
      );
    }

    static List<FoodItem> suggestMeal({
      required double remaining,
      required String pref,
      required List<FoodItem> foodDb,
    }) {
      final filtered = pref.isEmpty
          ? foodDb
          : foodDb.where((f) => f.category.toLowerCase().contains(pref.toLowerCase())).toList();
      final available = filtered.isEmpty ? foodDb : filtered;
      final sorted = [...available]..sort((a, b) => a.cost.compareTo(b.cost));
      final suggestions = <FoodItem>[];
      double usedCalories = 0;
      for (final item in sorted) {
        if (usedCalories + item.calories <= remaining) {
          suggestions.add(item);
          usedCalories += item.calories;
          if (suggestions.length >= 3) break;
        }
      }
      return suggestions;
    }

    static SetRecord? bestSet(List<SetRecord> sets) {
      if (sets.isEmpty) return null;
      return sets.reduce(
        (a, b) => epley(a.weight, a.reps) >= epley(b.weight, b.reps) ? a : b,
      );
    }

    static double epley(double weight, int reps) {
      if (reps <= 1) return weight;
      return weight * (1 + reps / 30.0);
    }

    static double volume(List<SetRecord> sets) {
      return sets.fold(0, (sum, s) => sum + s.weight * s.reps);
    }

    static RepSuggestion? repSuggestion(int reps) {
      if (reps >= 12) {
        return const RepSuggestion(type: 'up', arabicText: 'ارفع الوزن', englishText: 'Increase weight');
      } else if (reps <= 4) {
        return const RepSuggestion(type: 'down', arabicText: 'خفّف الوزن', englishText: 'Decrease weight');
      }
      return null;
    }
  
    /// ضبط القيم الغذائية بناءً على الكمية المحددة
    static FoodItem adjustByAmount(FoodItem food, double amount) {
      final ratio = amount / (food.amount > 0 ? food.amount : 100);
      return FoodItem(
        id: food.id,
        name: food.name,
        nameEn: food.nameEn,
        category: food.category,
        aliases: food.aliases,
        cost: food.cost,
        amount: amount,
        calories: food.calories * ratio,
        protein: food.protein * ratio,
        carbs: food.carbs * ratio,
        fat: food.fat * ratio,
        fiber: food.fiber * ratio,
      );
    }
  }