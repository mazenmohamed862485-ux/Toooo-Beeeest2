// ============================================================
// TO Best — home/presentation/providers/home_provider.dart
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/data/models/health_model.dart';
import 'package:shared/data/models/food_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import 'package:isar/isar.dart';
import 'package:shared/data/models/workout_model.dart';
part 'home_provider.g.dart';

/// بيانات الشاشة الرئيسية
class HomeData {
  const HomeData({
    this.todaySteps = 0,
    this.todayCalories = 0,
    this.lastSleepHours = 0,
    this.weeklyWorkouts = 0,
  });

  final int todaySteps;
  final int todayCalories;
  final double lastSleepHours;
  final int weeklyWorkouts;
}

@riverpod
Future<HomeData> homeData(HomeDataRef ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const HomeData();

  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  final today = DateTime.now();
  final todayMs = DateTime(today.year, today.month, today.day)
      .millisecondsSinceEpoch;

  // خطوات اليوم
  final healthToday = await db.healthDataIsarModels
      .filter()
      .userIdEqualTo(user.uid)
      .dateMsGreaterThan(todayMs - 1)
      .findFirst();

  // سعرات اليوم
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final meals = await db.mealLogIsarModels
      .filter()
      .userIdEqualTo(user.uid)
      .dateMsGreaterThan(todayStart.millisecondsSinceEpoch)
      .dateMsLessThan(todayEnd.millisecondsSinceEpoch)
      .findAll();

  double totalCal = 0;
  for (final meal in meals) {
    // نحسب من JSON items
    // (حساب مبسّط — يمكن توسيعه)
  }

  // تمارين الأسبوع
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final workoutsThisWeek = await db.workoutSessionIsarModels
      .filter()
      .userIdEqualTo(user.uid)
      .dateMsGreaterThan(DateTime(
              weekStart.year, weekStart.month, weekStart.day)
          .millisecondsSinceEpoch)
      .isCompletedEqualTo(true)
      .count();

  return HomeData(
    todaySteps: healthToday?.steps ?? 0,
    todayCalories: totalCal.round(),
    lastSleepHours: healthToday != null
        ? healthToday.sleepHours + healthToday.sleepMinutes / 60
        : 0,
    weeklyWorkouts: workoutsThisWeek,
  );
}
