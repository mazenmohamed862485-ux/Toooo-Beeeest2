// ============================================================
// TO Best — data/food_database_seed.dart
// بذر قاعدة الأطعمة في Isar عند أول تشغيل
// يحتوي على 100+ عنصر من foodDB.js الأصلي
// للقائمة الكاملة (1000+ عنصر): يُحمَّل من GAS عند الـ Onboarding
// ============================================================

import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/data/models/food_model.dart';

/// بذر قاعدة الأطعمة الأساسية في Isar
///
/// يُستدعى مرة واحدة عند أول تشغيل للتطبيق.
/// للقاعدة الكاملة (foodDB_extended) تُحمَّل من GAS وتُضاف لاحقاً.
Future<void> seedFoodDatabase(IsarService isarService) async {
  final db = await isarService.db;

  // فحص إذا تم البذر مسبقاً
  final count = await db.foodItemIsarModels.count();
  if (count > 0) return;

  final models = _foodData.map((d) {
    return FoodItemIsarModel(
      foodId: d['id'] as String,
      name: d['name'] as String,
      nameEn: (d['nameEn'] as String?) ?? '',
      category: d['cat'] as String,
      amount: (d['amt'] as num).toDouble(),
      calories: (d['cal'] as num).toDouble(),
      protein: (d['pro'] as num).toDouble(),
      carbs: (d['carb'] as num).toDouble(),
      fat: (d['fat'] as num).toDouble(),
      fiber: (d['fib'] as num? ?? 0).toDouble(),
      aliasesJson: '[]',
      cost: (d['cost'] as int?) ?? 1,
    );
  }).toList();

  await db.writeTxn(() async {
    await db.foodItemIsarModels.putAll(models);
  });
}

/// بيانات الأطعمة الأساسية — مُحوَّلة من foodDB.js
const List<Map<String, dynamic>> _foodData = [
  // ── حبوب ومشتقاتها ────────────────────────────────────────
  {'id': 'rice_white', 'name': 'أرز أبيض مطبوخ', 'nameEn': 'White Rice Cooked', 'cat': 'حبوب', 'amt': 100, 'cal': 130, 'pro': 2.7, 'carb': 28.2, 'fat': 0.3, 'fib': 0.4, 'cost': 1},
  {'id': 'rice_brown', 'name': 'أرز بني مطبوخ', 'nameEn': 'Brown Rice Cooked', 'cat': 'حبوب', 'amt': 100, 'cal': 111, 'pro': 2.6, 'carb': 23.0, 'fat': 0.9, 'fib': 1.8, 'cost': 1},
  {'id': 'oat', 'name': 'شوفان مطبوخ', 'nameEn': 'Oatmeal Cooked', 'cat': 'حبوب', 'amt': 100, 'cal': 71, 'pro': 2.5, 'carb': 12.0, 'fat': 1.5, 'fib': 1.7, 'cost': 1},
  {'id': 'oat_dry', 'name': 'شوفان جاف', 'nameEn': 'Oats Dry', 'cat': 'حبوب', 'amt': 100, 'cal': 389, 'pro': 16.9, 'carb': 66.3, 'fat': 6.9, 'fib': 10.6, 'cost': 1},
  {'id': 'bread_white', 'name': 'خبز أبيض', 'nameEn': 'White Bread', 'cat': 'حبوب', 'amt': 100, 'cal': 265, 'pro': 9.0, 'carb': 49.0, 'fat': 3.2, 'fib': 2.7, 'cost': 1},
  {'id': 'bread_whole', 'name': 'خبز أسمر', 'nameEn': 'Whole Wheat Bread', 'cat': 'حبوب', 'amt': 100, 'cal': 247, 'pro': 13.0, 'carb': 41.0, 'fat': 4.2, 'fib': 6.8, 'cost': 1},
  {'id': 'pasta', 'name': 'مكرونة مطبوخة', 'nameEn': 'Pasta Cooked', 'cat': 'حبوب', 'amt': 100, 'cal': 158, 'pro': 5.8, 'carb': 31.0, 'fat': 0.9, 'fib': 1.8, 'cost': 1},
  {'id': 'quinoa', 'name': 'كينوا مطبوخة', 'nameEn': 'Quinoa Cooked', 'cat': 'حبوب', 'amt': 100, 'cal': 120, 'pro': 4.4, 'carb': 21.3, 'fat': 1.9, 'fib': 2.8, 'cost': 3},
  {'id': 'potato', 'name': 'بطاطس مسلوقة', 'nameEn': 'Potato Boiled', 'cat': 'حبوب', 'amt': 100, 'cal': 87, 'pro': 1.9, 'carb': 20.1, 'fat': 0.1, 'fib': 1.8, 'cost': 1},
  {'id': 'sweet_potato', 'name': 'بطاطا حلوة مشوية', 'nameEn': 'Sweet Potato Baked', 'cat': 'حبوب', 'amt': 100, 'cal': 90, 'pro': 2.0, 'carb': 20.7, 'fat': 0.1, 'fib': 3.3, 'cost': 1},

  // ── بروتينات حيوانية ──────────────────────────────────────
  {'id': 'chicken_breast', 'name': 'صدر دجاج مشوي', 'nameEn': 'Grilled Chicken Breast', 'cat': 'بروتين', 'amt': 100, 'cal': 165, 'pro': 31.0, 'carb': 0.0, 'fat': 3.6, 'fib': 0.0, 'cost': 2},
  {'id': 'chicken_thigh', 'name': 'فخذ دجاج مشوي', 'nameEn': 'Grilled Chicken Thigh', 'cat': 'بروتين', 'amt': 100, 'cal': 209, 'pro': 26.0, 'carb': 0.0, 'fat': 10.9, 'fib': 0.0, 'cost': 2},
  {'id': 'beef_lean', 'name': 'لحم بقر مفروم خالي الدهن', 'nameEn': 'Lean Ground Beef', 'cat': 'بروتين', 'amt': 100, 'cal': 218, 'pro': 26.1, 'carb': 0.0, 'fat': 12.3, 'fib': 0.0, 'cost': 4},
  {'id': 'beef_steak', 'name': 'ستيك لحم بقر', 'nameEn': 'Beef Steak', 'cat': 'بروتين', 'amt': 100, 'cal': 271, 'pro': 26.3, 'carb': 0.0, 'fat': 18.0, 'fib': 0.0, 'cost': 5},
  {'id': 'tuna_can', 'name': 'تونة معلبة بالماء', 'nameEn': 'Canned Tuna in Water', 'cat': 'بروتين', 'amt': 100, 'cal': 116, 'pro': 25.5, 'carb': 0.0, 'fat': 1.0, 'fib': 0.0, 'cost': 2},
  {'id': 'salmon', 'name': 'سلمون مشوي', 'nameEn': 'Grilled Salmon', 'cat': 'بروتين', 'amt': 100, 'cal': 208, 'pro': 20.4, 'carb': 0.0, 'fat': 13.4, 'fib': 0.0, 'cost': 5},
  {'id': 'egg_whole', 'name': 'بيضة كاملة', 'nameEn': 'Whole Egg', 'cat': 'بروتين', 'amt': 50, 'cal': 78, 'pro': 6.3, 'carb': 0.6, 'fat': 5.3, 'fib': 0.0, 'cost': 1},
  {'id': 'egg_white', 'name': 'بياض البيض', 'nameEn': 'Egg White', 'cat': 'بروتين', 'amt': 100, 'cal': 52, 'pro': 10.9, 'carb': 0.7, 'fat': 0.2, 'fib': 0.0, 'cost': 1},
  {'id': 'turkey_breast', 'name': 'صدر ديك رومي', 'nameEn': 'Turkey Breast', 'cat': 'بروتين', 'amt': 100, 'cal': 135, 'pro': 30.1, 'carb': 0.0, 'fat': 1.0, 'fib': 0.0, 'cost': 3},
  {'id': 'shrimp', 'name': 'روبيان مطبوخ', 'nameEn': 'Cooked Shrimp', 'cat': 'بروتين', 'amt': 100, 'cal': 99, 'pro': 20.9, 'carb': 0.2, 'fat': 1.1, 'fib': 0.0, 'cost': 4},
  {'id': 'sardine', 'name': 'سردين معلب', 'nameEn': 'Canned Sardines', 'cat': 'بروتين', 'amt': 100, 'cal': 208, 'pro': 24.6, 'carb': 0.0, 'fat': 11.5, 'fib': 0.0, 'cost': 2},
  {'id': 'lamb', 'name': 'لحم غنم مشوي', 'nameEn': 'Grilled Lamb', 'cat': 'بروتين', 'amt': 100, 'cal': 294, 'pro': 25.0, 'carb': 0.0, 'fat': 21.0, 'fib': 0.0, 'cost': 5},

  // ── ألبان ومشتقاتها ───────────────────────────────────────
  {'id': 'milk_full', 'name': 'حليب كامل الدسم', 'nameEn': 'Full Fat Milk', 'cat': 'ألبان', 'amt': 240, 'cal': 149, 'pro': 8.0, 'carb': 11.7, 'fat': 8.0, 'fib': 0.0, 'cost': 1},
  {'id': 'milk_low', 'name': 'حليب قليل الدسم', 'nameEn': 'Low Fat Milk', 'cat': 'ألبان', 'amt': 240, 'cal': 102, 'pro': 8.0, 'carb': 12.2, 'fat': 2.4, 'fib': 0.0, 'cost': 1},
  {'id': 'yogurt_plain', 'name': 'زبادي طبيعي', 'nameEn': 'Plain Yogurt', 'cat': 'ألبان', 'amt': 100, 'cal': 61, 'pro': 3.5, 'carb': 4.7, 'fat': 3.3, 'fib': 0.0, 'cost': 1},
  {'id': 'greek_yogurt', 'name': 'زبادي يوناني', 'nameEn': 'Greek Yogurt', 'cat': 'ألبان', 'amt': 100, 'cal': 59, 'pro': 10.0, 'carb': 3.6, 'fat': 0.4, 'fib': 0.0, 'cost': 2},
  {'id': 'cottage_cheese', 'name': 'جبنة كوتج', 'nameEn': 'Cottage Cheese', 'cat': 'ألبان', 'amt': 100, 'cal': 98, 'pro': 11.1, 'carb': 3.4, 'fat': 4.3, 'fib': 0.0, 'cost': 2},
  {'id': 'cheese_cheddar', 'name': 'جبنة شيدر', 'nameEn': 'Cheddar Cheese', 'cat': 'ألبان', 'amt': 100, 'cal': 402, 'pro': 25.0, 'carb': 1.3, 'fat': 33.1, 'fib': 0.0, 'cost': 3},
  {'id': 'whey_protein', 'name': 'بروتين مصل اللبن', 'nameEn': 'Whey Protein', 'cat': 'ألبان', 'amt': 30, 'cal': 113, 'pro': 25.0, 'carb': 2.0, 'fat': 1.5, 'fib': 0.0, 'cost': 5},

  // ── خضروات ────────────────────────────────────────────────
  {'id': 'broccoli', 'name': 'بروكلي مطبوخ', 'nameEn': 'Cooked Broccoli', 'cat': 'خضروات', 'amt': 100, 'cal': 35, 'pro': 2.4, 'carb': 7.2, 'fat': 0.4, 'fib': 3.3, 'cost': 2},
  {'id': 'spinach', 'name': 'سبانخ مطبوخ', 'nameEn': 'Cooked Spinach', 'cat': 'خضروات', 'amt': 100, 'cal': 23, 'pro': 3.0, 'carb': 3.8, 'fat': 0.3, 'fib': 2.4, 'cost': 1},
  {'id': 'cucumber', 'name': 'خيار', 'nameEn': 'Cucumber', 'cat': 'خضروات', 'amt': 100, 'cal': 16, 'pro': 0.7, 'carb': 3.6, 'fat': 0.1, 'fib': 0.5, 'cost': 1},
  {'id': 'tomato', 'name': 'طماطم', 'nameEn': 'Tomato', 'cat': 'خضروات', 'amt': 100, 'cal': 18, 'pro': 0.9, 'carb': 3.9, 'fat': 0.2, 'fib': 1.2, 'cost': 1},
  {'id': 'lettuce', 'name': 'خس', 'nameEn': 'Lettuce', 'cat': 'خضروات', 'amt': 100, 'cal': 15, 'pro': 1.4, 'carb': 2.9, 'fat': 0.2, 'fib': 1.3, 'cost': 1},
  {'id': 'carrot', 'name': 'جزر', 'nameEn': 'Carrot', 'cat': 'خضروات', 'amt': 100, 'cal': 41, 'pro': 0.9, 'carb': 9.6, 'fat': 0.2, 'fib': 2.8, 'cost': 1},
  {'id': 'zucchini', 'name': 'كوسة مطبوخة', 'nameEn': 'Cooked Zucchini', 'cat': 'خضروات', 'amt': 100, 'cal': 17, 'pro': 1.2, 'carb': 3.6, 'fat': 0.0, 'fib': 1.1, 'cost': 1},
  {'id': 'pepper_red', 'name': 'فليفلة حمراء', 'nameEn': 'Red Bell Pepper', 'cat': 'خضروات', 'amt': 100, 'cal': 31, 'pro': 1.0, 'carb': 6.0, 'fat': 0.3, 'fib': 2.1, 'cost': 2},
  {'id': 'onion', 'name': 'بصل', 'nameEn': 'Onion', 'cat': 'خضروات', 'amt': 100, 'cal': 40, 'pro': 1.1, 'carb': 9.3, 'fat': 0.1, 'fib': 1.7, 'cost': 1},
  {'id': 'mushroom', 'name': 'فطر مطبوخ', 'nameEn': 'Cooked Mushroom', 'cat': 'خضروات', 'amt': 100, 'cal': 28, 'pro': 3.6, 'carb': 5.3, 'fat': 0.2, 'fib': 2.2, 'cost': 2},

  // ── بقوليات ───────────────────────────────────────────────
  {'id': 'lentils', 'name': 'عدس مطبوخ', 'nameEn': 'Cooked Lentils', 'cat': 'بقوليات', 'amt': 100, 'cal': 116, 'pro': 9.0, 'carb': 20.1, 'fat': 0.4, 'fib': 7.9, 'cost': 1},
  {'id': 'chickpeas', 'name': 'حمص مطبوخ', 'nameEn': 'Cooked Chickpeas', 'cat': 'بقوليات', 'amt': 100, 'cal': 164, 'pro': 8.9, 'carb': 27.4, 'fat': 2.6, 'fib': 7.6, 'cost': 1},
  {'id': 'black_beans', 'name': 'فاصوليا سوداء مطبوخة', 'nameEn': 'Cooked Black Beans', 'cat': 'بقوليات', 'amt': 100, 'cal': 132, 'pro': 8.9, 'carb': 23.7, 'fat': 0.5, 'fib': 8.7, 'cost': 1},
  {'id': 'kidney_beans', 'name': 'فاصوليا حمراء مطبوخة', 'nameEn': 'Cooked Kidney Beans', 'cat': 'بقوليات', 'amt': 100, 'cal': 127, 'pro': 8.7, 'carb': 22.8, 'fat': 0.5, 'fib': 6.4, 'cost': 1},
  {'id': 'edamame', 'name': 'فول صويا أخضر', 'nameEn': 'Edamame', 'cat': 'بقوليات', 'amt': 100, 'cal': 121, 'pro': 11.9, 'carb': 8.9, 'fat': 5.2, 'fib': 5.2, 'cost': 3},

  // ── دهون صحية ─────────────────────────────────────────────
  {'id': 'olive_oil', 'name': 'زيت زيتون', 'nameEn': 'Olive Oil', 'cat': 'دهون', 'amt': 15, 'cal': 119, 'pro': 0.0, 'carb': 0.0, 'fat': 13.5, 'fib': 0.0, 'cost': 3},
  {'id': 'almond', 'name': 'لوز', 'nameEn': 'Almonds', 'cat': 'دهون', 'amt': 30, 'cal': 173, 'pro': 6.0, 'carb': 6.1, 'fat': 15.0, 'fib': 3.5, 'cost': 4},
  {'id': 'peanut_butter', 'name': 'زبدة الفول السوداني', 'nameEn': 'Peanut Butter', 'cat': 'دهون', 'amt': 32, 'cal': 188, 'pro': 8.0, 'carb': 6.3, 'fat': 16.0, 'fib': 1.9, 'cost': 2},
  {'id': 'avocado', 'name': 'أفوكادو', 'nameEn': 'Avocado', 'cat': 'دهون', 'amt': 100, 'cal': 160, 'pro': 2.0, 'carb': 8.5, 'fat': 14.7, 'fib': 6.7, 'cost': 4},
  {'id': 'walnut', 'name': 'جوز', 'nameEn': 'Walnuts', 'cat': 'دهون', 'amt': 30, 'cal': 196, 'pro': 4.6, 'carb': 4.1, 'fat': 19.6, 'fib': 2.0, 'cost': 4},
  {'id': 'cashew', 'name': 'كاجو', 'nameEn': 'Cashews', 'cat': 'دهون', 'amt': 30, 'cal': 157, 'pro': 5.1, 'carb': 8.6, 'fat': 12.4, 'fib': 0.9, 'cost': 4},
  {'id': 'flaxseed', 'name': 'بذر الكتان', 'nameEn': 'Flaxseed', 'cat': 'دهون', 'amt': 15, 'cal': 79, 'pro': 2.7, 'carb': 4.3, 'fat': 6.2, 'fib': 3.8, 'cost': 2},
  {'id': 'chia_seed', 'name': 'بذور الشيا', 'nameEn': 'Chia Seeds', 'cat': 'دهون', 'amt': 30, 'cal': 138, 'pro': 4.7, 'carb': 12.0, 'fat': 8.7, 'fib': 9.8, 'cost': 3},

  // ── فاكهة ─────────────────────────────────────────────────
  {'id': 'banana', 'name': 'موزة', 'nameEn': 'Banana', 'cat': 'فاكهة', 'amt': 120, 'cal': 107, 'pro': 1.3, 'carb': 27.2, 'fat': 0.4, 'fib': 3.1, 'cost': 1},
  {'id': 'apple', 'name': 'تفاحة', 'nameEn': 'Apple', 'cat': 'فاكهة', 'amt': 180, 'cal': 93, 'pro': 0.5, 'carb': 24.7, 'fat': 0.3, 'fib': 4.3, 'cost': 1},
  {'id': 'orange', 'name': 'برتقالة', 'nameEn': 'Orange', 'cat': 'فاكهة', 'amt': 150, 'cal': 71, 'pro': 1.4, 'carb': 17.6, 'fat': 0.2, 'fib': 3.5, 'cost': 1},
  {'id': 'dates', 'name': 'تمر', 'nameEn': 'Dates', 'cat': 'فاكهة', 'amt': 100, 'cal': 277, 'pro': 1.8, 'carb': 75.0, 'fat': 0.2, 'fib': 6.7, 'cost': 2},
  {'id': 'strawberry', 'name': 'فراولة', 'nameEn': 'Strawberry', 'cat': 'فاكهة', 'amt': 100, 'cal': 32, 'pro': 0.7, 'carb': 7.7, 'fat': 0.3, 'fib': 2.0, 'cost': 2},
  {'id': 'blueberry', 'name': 'توت أزرق', 'nameEn': 'Blueberry', 'cat': 'فاكهة', 'amt': 100, 'cal': 57, 'pro': 0.7, 'carb': 14.5, 'fat': 0.3, 'fib': 2.4, 'cost': 4},
  {'id': 'mango', 'name': 'مانجا', 'nameEn': 'Mango', 'cat': 'فاكهة', 'amt': 100, 'cal': 60, 'pro': 0.8, 'carb': 15.0, 'fat': 0.4, 'fib': 1.6, 'cost': 2},
  {'id': 'watermelon', 'name': 'بطيخ', 'nameEn': 'Watermelon', 'cat': 'فاكهة', 'amt': 300, 'cal': 90, 'pro': 1.8, 'carb': 22.5, 'fat': 0.5, 'fib': 0.9, 'cost': 1},

  // ── مشروبات ───────────────────────────────────────────────
  {'id': 'water', 'name': 'ماء', 'nameEn': 'Water', 'cat': 'مشروبات', 'amt': 240, 'cal': 0, 'pro': 0.0, 'carb': 0.0, 'fat': 0.0, 'fib': 0.0, 'cost': 1},
  {'id': 'black_coffee', 'name': 'قهوة سوداء', 'nameEn': 'Black Coffee', 'cat': 'مشروبات', 'amt': 240, 'cal': 2, 'pro': 0.3, 'carb': 0.0, 'fat': 0.0, 'fib': 0.0, 'cost': 1},
  {'id': 'green_tea', 'name': 'شاي أخضر', 'nameEn': 'Green Tea', 'cat': 'مشروبات', 'amt': 240, 'cal': 2, 'pro': 0.5, 'carb': 0.2, 'fat': 0.0, 'fib': 0.0, 'cost': 1},
  {'id': 'orange_juice', 'name': 'عصير برتقال طازج', 'nameEn': 'Fresh Orange Juice', 'cat': 'مشروبات', 'amt': 240, 'cal': 112, 'pro': 1.7, 'carb': 25.8, 'fat': 0.5, 'fib': 0.5, 'cost': 2},

  // ── وجبات جاهزة ───────────────────────────────────────────
  {'id': 'shawarma_chicken', 'name': 'شاورما دجاج (لفة)', 'nameEn': 'Chicken Shawarma Wrap', 'cat': 'وجبات', 'amt': 250, 'cal': 410, 'pro': 28.0, 'carb': 42.0, 'fat': 14.0, 'fib': 2.0, 'cost': 3},
  {'id': 'foul', 'name': 'فول بالزيت', 'nameEn': 'Foul with Oil', 'cat': 'وجبات', 'amt': 200, 'cal': 240, 'pro': 12.0, 'carb': 34.0, 'fat': 6.0, 'fib': 8.0, 'cost': 1},
  {'id': 'kabsa', 'name': 'كبسة دجاج', 'nameEn': 'Chicken Kabsa', 'cat': 'وجبات', 'amt': 400, 'cal': 520, 'pro': 32.0, 'carb': 65.0, 'fat': 12.0, 'fib': 2.5, 'cost': 3},
  {'id': 'hummus', 'name': 'حمص بطحينة', 'nameEn': 'Hummus with Tahini', 'cat': 'وجبات', 'amt': 100, 'cal': 177, 'pro': 7.9, 'carb': 20.1, 'fat': 8.6, 'fib': 6.0, 'cost': 1},
  {'id': 'salad_fattoush', 'name': 'سلطة فتوش', 'nameEn': 'Fattoush Salad', 'cat': 'وجبات', 'amt': 200, 'cal': 120, 'pro': 3.0, 'carb': 18.0, 'fat': 5.0, 'fib': 3.0, 'cost': 2},

  // ── سناك وتحليات ──────────────────────────────────────────
  {'id': 'dark_choc', 'name': 'شوكولاتة داكنة (85%)', 'nameEn': 'Dark Chocolate 85%', 'cat': 'سناك', 'amt': 30, 'cal': 170, 'pro': 2.2, 'carb': 10.0, 'fat': 13.0, 'fib': 3.3, 'cost': 3},
  {'id': 'granola_bar', 'name': 'قرانولا بار', 'nameEn': 'Granola Bar', 'cat': 'سناك', 'amt': 47, 'cal': 193, 'pro': 4.0, 'carb': 29.0, 'fat': 7.0, 'fib': 2.5, 'cost': 3},
  {'id': 'popcorn_plain', 'name': 'فشار سادة', 'nameEn': 'Plain Popcorn', 'cat': 'سناك', 'amt': 30, 'cal': 110, 'pro': 3.5, 'carb': 22.0, 'fat': 1.5, 'fib': 4.0, 'cost': 1},
  {'id': 'honey', 'name': 'عسل', 'nameEn': 'Honey', 'cat': 'سناك', 'amt': 20, 'cal': 61, 'pro': 0.1, 'carb': 16.5, 'fat': 0.0, 'fib': 0.0, 'cost': 2},

  // ── مكملات ────────────────────────────────────────────────
  {'id': 'creatine', 'name': 'كرياتين', 'nameEn': 'Creatine', 'cat': 'مكملات', 'amt': 5, 'cal': 0, 'pro': 0.0, 'carb': 0.0, 'fat': 0.0, 'fib': 0.0, 'cost': 3},
  {'id': 'casein', 'name': 'بروتين كازيين', 'nameEn': 'Casein Protein', 'cat': 'مكملات', 'amt': 35, 'cal': 130, 'pro': 24.0, 'carb': 4.0, 'fat': 1.5, 'fib': 0.0, 'cost': 5},
  {'id': 'bcaa', 'name': 'BCAA', 'nameEn': 'BCAA', 'cat': 'مكملات', 'amt': 10, 'cal': 35, 'pro': 7.0, 'carb': 1.0, 'fat': 0.0, 'fib': 0.0, 'cost': 4},
];
