// TO Best — data/models/health_model.dart

import 'package:isar/isar.dart';
import '../../domain/entities/health_data.dart';

part 'health_model.g.dart';

@Collection()
class HealthDataIsarModel {
  HealthDataIsarModel({
    required this.userId,
    required this.dateMs,
    this.steps = 0,
    this.distanceKm = 0,
    this.burnedCalories = 0,
    this.walkingMinutes = 0,
    this.sleepHours = 0,
    this.sleepMinutes = 0,
    this.sleepQuality = 'fair',
    this.syncedToRemote = false,
    this.updatedAtMs,
  });

  Id id = Isar.autoIncrement;

  @Index(
    composite: [CompositeIndex('dateMs')],
    unique: true,
  )
  final String userId;

  @Index()
  final int dateMs;

  int steps;
  double distanceKm;
  double burnedCalories;
  int walkingMinutes;
  int sleepHours;
  int sleepMinutes;
  String sleepQuality;
  bool syncedToRemote;
  final int? updatedAtMs;

  HealthData toEntity() {
    SleepData? sleep;
    if (sleepHours > 0 || sleepMinutes > 0) {
      sleep = SleepData(
        durationHours: sleepHours,
        durationMinutes: sleepMinutes,
        quality: SleepQuality.values.firstWhere(
          (q) => q.name == sleepQuality,
          orElse: () => SleepQuality.fair,
        ),
      );
    }
    return HealthData(
      userId: userId,
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      steps: steps,
      distanceKm: distanceKm,
      burnedCalories: burnedCalories,
      walkingMinutes: walkingMinutes,
      sleep: sleep,
      updatedAt: updatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs!)
          : null,
    );
  }

  factory HealthDataIsarModel.fromEntity(HealthData entity) {
    return HealthDataIsarModel(
      userId: entity.userId,
      dateMs: entity.date.millisecondsSinceEpoch,
      steps: entity.steps,
      distanceKm: entity.distanceKm,
      burnedCalories: entity.burnedCalories,
      walkingMinutes: entity.walkingMinutes,
      sleepHours: entity.sleep?.durationHours ?? 0,
      sleepMinutes: entity.sleep?.durationMinutes ?? 0,
      sleepQuality: entity.sleep?.quality.name ?? 'fair',
      updatedAtMs: entity.updatedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
