// ============================================================
// TO Best — data/models/workout_model.dart
// Isar Schema للتمارين
// ============================================================

import 'dart:convert';
import 'package:isar/isar.dart';
import '../../domain/entities/workout_session.dart';

part 'workout_model.g.dart';

/// Isar Schema لجلسة التمرين
@Collection()
class WorkoutSessionIsarModel {
  WorkoutSessionIsarModel({
    required this.sessionId,
    required this.userId,
    required this.sessionName,
    required this.programId,
    required this.dateMs,
    required this.exercisesJson,
    required this.warmupsJson,
    this.isCompleted = false,
    this.durationMinutes = 0,
    this.notes = '',
    this.syncedToRemote = false,
    this.updatedAtMs,
  });

  Id id = Isar.autoIncrement;

  @Index()
  final String sessionId;

  @Index()
  final String userId;

  final String sessionName;
  final String programId;

  @Index()
  final int dateMs;

  /// سجلات التمارين كـ JSON string
  final String exercisesJson;

  /// سجلات الإحماء كـ JSON string
  final String warmupsJson;

  bool isCompleted;
  int durationMinutes;
  final String notes;

  /// هل تمت مزامنته مع GAS
  bool syncedToRemote;

  final int? updatedAtMs;

  WorkoutSession toEntity() {
    final exercisesList =
        (jsonDecode(exercisesJson) as List<dynamic>)
            .map((e) => _exerciseFromJson(e as Map<String, dynamic>))
            .toList();

    final warmupsList =
        (jsonDecode(warmupsJson) as List<dynamic>)
            .map((w) => _warmupFromJson(w as Map<String, dynamic>))
            .toList();

    return WorkoutSession(
      id: sessionId,
      userId: userId,
      sessionName: sessionName,
      programId: programId,
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      exercises: exercisesList,
      warmups: warmupsList,
      isCompleted: isCompleted,
      durationMinutes: durationMinutes,
      notes: notes,
    );
  }

  factory WorkoutSessionIsarModel.fromEntity(WorkoutSession entity) {
    return WorkoutSessionIsarModel(
      sessionId: entity.id,
      userId: entity.userId,
      sessionName: entity.sessionName,
      programId: entity.programId,
      dateMs: entity.date.millisecondsSinceEpoch,
      exercisesJson: jsonEncode(entity.exercises.map(_exerciseToJson).toList()),
      warmupsJson: jsonEncode(entity.warmups.map(_warmupToJson).toList()),
      isCompleted: entity.isCompleted,
      durationMinutes: entity.durationMinutes,
      notes: entity.notes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static ExerciseLog _exerciseFromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseName: json['name'] as String? ?? '',
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((s) => _setFromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String? ?? '',
      alternativeUsed: json['alt'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _exerciseToJson(ExerciseLog ex) => {
        'name': ex.exerciseName,
        'sets': ex.sets.map(_setToJson).toList(),
        'notes': ex.notes,
        'alt': ex.alternativeUsed,
      };

  static SetRecord _setFromJson(Map<String, dynamic> json) {
    return SetRecord(
      weight: (json['w'] as num?)?.toDouble() ?? 0,
      reps: (json['r'] as num?)?.toInt() ?? 0,
      rpe: (json['rpe'] as num?)?.toInt(),
      rir: (json['rir'] as num?)?.toInt(),
      isWarmup: json['wu'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _setToJson(SetRecord s) => {
        'w': s.weight,
        'r': s.reps,
        if (s.rpe != null) 'rpe': s.rpe,
        if (s.rir != null) 'rir': s.rir,
        if (s.isWarmup) 'wu': true,
      };

  static WarmupLog _warmupFromJson(Map<String, dynamic> json) {
    return WarmupLog(
      name: json['name'] as String? ?? '',
      reps: json['reps'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      isDone: json['done'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _warmupToJson(WarmupLog w) => {
        'name': w.name,
        'reps': w.reps,
        'weight': w.weight,
        'done': w.isDone,
      };
}

/// Isar Schema لـ ExerciseLog (مستقل للبحث السريع)
@Collection()
class ExerciseLogIsarModel {
  ExerciseLogIsarModel({
    required this.sessionId,
    required this.userId,
    required this.exerciseName,
    required this.dateMs,
    required this.bestWeight,
    required this.bestReps,
    required this.best1RM,
    required this.totalVolume,
  });

  Id id = Isar.autoIncrement;

  @Index()
  final String sessionId;

  @Index()
  final String userId;

  @Index()
  final String exerciseName;

  @Index()
  final int dateMs;

  final double bestWeight;
  final int bestReps;
  final double best1RM;
  final double totalVolume;
}
