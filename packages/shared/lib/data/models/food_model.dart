// ============================================================
// TO Best — data/models/food_model.dart
// Isar Schemas للأطعمة والوجبات
// ============================================================

import 'dart:convert';
import 'package:isar/isar.dart';
import '../../domain/entities/nutrition.dart';

part 'food_model.g.dart';

/// Isar Schema للعنصر الغذائي
@Collection()
class FoodItemIsarModel {
  FoodItemIsarModel({
    required this.foodId,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.aliasesJson = '[]',
    this.cost = 1,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String foodId;

  @Index()
  final String name;

  final String nameEn;

  @Index()
  final String category;

  final double amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  /// قائمة الأسماء البديلة كـ JSON
  final String aliasesJson;

  final int cost;

  FoodItem toEntity() {
    final aliases =
        (jsonDecode(aliasesJson) as List<dynamic>).cast<String>();
    return FoodItem(
      id: foodId,
      name: name,
      nameEn: nameEn,
      category: category,
      amount: amount,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      aliases: aliases,
      cost: cost,
    );
  }

  factory FoodItemIsarModel.fromEntity(FoodItem entity) {
    return FoodItemIsarModel(
      foodId: entity.id,
      name: entity.name,
      nameEn: entity.nameEn,
      category: entity.category,
      amount: entity.amount,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      fiber: entity.fiber,
      aliasesJson: jsonEncode(entity.aliases),
      cost: entity.cost,
    );
  }

  factory FoodItemIsarModel.fromJson(Map<String, dynamic> json) {
    final aliases = (json['aliases'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return FoodItemIsarModel(
      foodId: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      category: json['cat']?.toString() ?? json['category']?.toString() ?? '',
      amount: (json['amt'] as num?)?.toDouble() ?? 100,
      calories: (json['cal'] as num?)?.toDouble() ?? 0,
      protein: (json['pro'] as num?)?.toDouble() ?? 0,
      carbs: (json['carb'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fib'] as num?)?.toDouble() ?? 0,
      aliasesJson: jsonEncode(aliases),
      cost: (json['cost'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Isar Schema لسجل وجبة يومية
@Collection()
class MealLogIsarModel {
  MealLogIsarModel({
    required this.mealId,
    required this.userId,
    required this.dateMs,
    required this.mealType,
    required this.itemsJson,
    this.syncedToRemote = false,
    this.updatedAtMs,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String mealId;

  @Index()
  final String userId;

  @Index()
  final int dateMs;

  final String mealType;

  /// عناصر الوجبة كـ JSON
  final String itemsJson;

  bool syncedToRemote;
  final int? updatedAtMs;

  MealLog toEntity() {
    final items =
        (jsonDecode(itemsJson) as List<dynamic>)
            .map((i) => _itemFromJson(i as Map<String, dynamic>))
            .toList();
    return MealLog(
      id: mealId,
      userId: userId,
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      mealType: mealType,
      items: items,
      updatedAt: updatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs!)
          : null,
    );
  }

  factory MealLogIsarModel.fromEntity(MealLog entity) {
    return MealLogIsarModel(
      mealId: entity.id,
      userId: entity.userId,
      dateMs: entity.date.millisecondsSinceEpoch,
      mealType: entity.mealType,
      itemsJson: jsonEncode(entity.items.map(_itemToJson).toList()),
      updatedAtMs: entity.updatedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static MealItemLog _itemFromJson(Map<String, dynamic> json) {
    return MealItemLog(
      foodId: json['id']?.toString() ?? '',
      foodName: json['name']?.toString() ?? '',
      amount: (json['amt'] as num?)?.toDouble() ?? 0,
      calories: (json['cal'] as num?)?.toDouble() ?? 0,
      protein: (json['pro'] as num?)?.toDouble() ?? 0,
      carbs: (json['carb'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fib'] as num?)?.toDouble() ?? 0,
    );
  }

  static Map<String, dynamic> _itemToJson(MealItemLog item) => {
        'id': item.foodId,
        'name': item.foodName,
        'amt': item.amount,
        'cal': item.calories,
        'pro': item.protein,
        'carb': item.carbs,
        'fat': item.fat,
        'fib': item.fiber,
      };
}
