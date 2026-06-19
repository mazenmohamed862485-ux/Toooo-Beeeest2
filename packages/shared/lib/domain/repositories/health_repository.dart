// TO Best — domain/repositories/health_repository.dart

import '../entities/health_data.dart';

abstract class HealthRepository {
  Future<HealthData?> getHealthData({
    required String userId,
    required DateTime date,
  });

  Future<void> saveHealthData(HealthData data);

  Future<void> updateSteps({
    required String userId,
    required DateTime date,
    required int steps,
    required double distanceKm,
    required double burnedCalories,
  });

  Future<void> saveSleepData({
    required String userId,
    required DateTime date,
    required SleepData sleep,
  });

  Future<WalkingGoal> getWalkingGoal(String userId);

  Future<void> saveWalkingGoal({
    required String userId,
    required WalkingGoal goal,
  });

  Future<void> syncHealthToRemote(String userId);
}
