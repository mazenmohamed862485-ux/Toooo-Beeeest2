// ============================================================
// TO Best — domain/entities/nutrition.dart
// كيانات التغذية والأطعمة في طبقة Domain
// ============================================================

import 'package:equatable/equatable.dart';

/// عنصر غذائي (من قاعدة البيانات)
class FoodItem extends Equatable {
  const FoodItem({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.aliases = const [],
    this.cost = 1,
  });

  final String id;

  /// الاسم بالعربي
  final String name;

  /// الاسم بالإنجليزي
  final String nameEn;

  /// الفئة (حبوب، بروتين، خضروات...)
  final String category;

  /// الكمية الافتراضية (بالجرام)
  final double amount;

  /// السعرات الحرارية
  final double calories;

  /// البروتين (جرام)
  final double protein;

  /// الكربوهيدرات (جرام)
  final double carbs;

  /// الدهون (جرام)
  final double fat;

  /// الألياف (جرام)
  final double fiber;

  /// أسماء بديلة للبحث
  final List<String> aliases;

  /// مستوى التكلفة (1-9)
  final int cost;

  @override
  List<Object?> get props => [id];

  FoodItem copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? category,
    double? amount,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    List<String>? aliases,
    int? cost,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      aliases: aliases ?? this.aliases,
      cost: cost ?? this.cost,
    );
  }
}

/// وجبة مُسجَّلة في يوم معين
class MealLog extends Equatable {
  const MealLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.items,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;

  /// نوع الوجبة (breakfast / lunch / dinner / snack)
  final String mealType;

  final List<MealItemLog> items;
  final DateTime? updatedAt;

  /// إجمالي السعرات الحرارية
  double get totalCalories =>
      items.fold(0, (sum, item) => sum + item.calories);

  /// إجمالي البروتين
  double get totalProtein => items.fold(0, (sum, item) => sum + item.protein);

  /// إجمالي الكربوهيدرات
  double get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);

  /// إجمالي الدهون
  double get totalFat => items.fold(0, (sum, item) => sum + item.fat);

  @override
  List<Object?> get props => [id, userId, date, mealType];
}

/// عنصر غذائي داخل وجبة مُسجَّلة
class MealItemLog extends Equatable {
  const MealItemLog({
    required this.foodId,
    required this.foodName,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final String foodId;
  final String foodName;

  /// الكمية المُتناوَلة (جرام)
  final double amount;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  @override
  List<Object?> get props => [foodId, amount];
}

/// ملخص التغذية اليومي
class DailyNutritionSummary extends Equatable {
  const DailyNutritionSummary({
    required this.date,
    required this.targetCalories,
    required this.consumedCalories,
    required this.targetProtein,
    required this.consumedProtein,
    required this.targetCarbs,
    required this.consumedCarbs,
    required this.targetFat,
    required this.consumedFat,
    required this.meals,
  });

  final DateTime date;
  final double targetCalories;
  final double consumedCalories;
  final double targetProtein;
  final double consumedProtein;
  final double targetCarbs;
  final double consumedCarbs;
  final double targetFat;
  final double consumedFat;
  final List<MealLog> meals;

  /// السعرات المتبقية
  double get remainingCalories => targetCalories - consumedCalories;

  /// نسبة اكتمال الهدف (0-1)
  double get completionRatio =>
      targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0, 1) : 0;

  @override
  List<Object?> get props => [date];
}

/// نتيجة حساب الماكرو
class MacroResult extends Equatable {
  const MacroResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  @override
  List<Object?> get props => [calories, protein, carbs, fat];
}

/// نتيجة تحليل نص الوجبة (parseMealText)
class MealParseResult extends Equatable {
  const MealParseResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.items,
    required this.unmatched,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  /// العناصر التي تم التعرف عليها
  final List<FoodItem> items;

  /// النصوص التي لم يتم التعرف عليها
  final List<String> unmatched;

  @override
  List<Object?> get props => [calories, items, unmatched];
}
