// ============================================================
// TO Best — workout/presentation/providers/workout_provider.dart
// إدارة حالة التمارين: برنامج + جلسة + تقييم
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/domain/entities/workout_session.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/infrastructure/sync_service.dart';
import 'package:shared/data/models/workout_model.dart';
import 'package:shared/utils/evaluator.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'program_definitions.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
part 'workout_provider.g.dart';

// ── برنامج اليوم ──────────────────────────────────────────────

/// الجلسة المقررة لليوم
@riverpod
Future<TodayWorkout?> todayWorkout(TodayWorkoutRef ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  // حساب الجلسة بناءً على البرنامج واليوم
  final program = user.program;
  final session = ProgramDefinitions.getTodaySession(
    program: program,
    programDays: user.programDays,
  );

  if (session == null) {
    return TodayWorkout(
      isRestDay: true,
      sessionName: '',
      exercises: [],
      warmups: [],
    );
  }

  // جلب تاريخ الجلسة من Isar
  final history = await ref.read(sessionHistoryProvider(
    SessionHistoryParams(
      userId: user.uid,
      sessionName: session.name,
      limit: 10,
    ),
  ).future);

  return TodayWorkout(
    isRestDay: false,
    sessionName: session.name,
    exercises: session.exercises,
    warmups: session.warmups,
    previousSession: history.isNotEmpty ? history.first : null,
  );
}

/// تاريخ جلسات محددة
@riverpod
Future<List<WorkoutSession>> sessionHistory(
  SessionHistoryRef ref,
  SessionHistoryParams params,
) async {
  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  final models = await db.workoutSessionIsarModels
      .filter()
      .userIdEqualTo(params.userId)
      .sessionNameEqualTo(params.sessionName)
      .sortByDateMsDesc()
      .limit(params.limit)
      .findAll();

  return models.map((m) => m.toEntity()).toList();
}

class SessionHistoryParams {
  const SessionHistoryParams({
    required this.userId,
    required this.sessionName,
    this.limit = 10,
  });

  final String userId;
  final String sessionName;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is SessionHistoryParams &&
      other.userId == userId &&
      other.sessionName == sessionName &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(userId, sessionName, limit);
}

// ── جلسة التمرين الحالية ──────────────────────────────────────

/// حالة جلسة التمرين النشطة
@riverpod
class ActiveWorkoutSession extends _$ActiveWorkoutSession {
  @override
  WorkoutSessionState? build() => null;

  /// بدء جلسة جديدة
  void startSession({
    required String userId,
    required String sessionName,
    required String programId,
    required List<ExerciseDefinition> exercises,
    required List<WarmupLog> warmups,
  }) {
    final sessionId = const Uuid().v4();
    state = WorkoutSessionState(
      sessionId: sessionId,
      userId: userId,
      sessionName: sessionName,
      programId: programId,
      startTime: DateTime.now(),
      exercises: exercises
          .map((e) => ExerciseState.fromDefinition(e))
          .toList(),
      warmups: warmups,
    );
  }

  /// تسجيل ست
  void logSet({
    required int exerciseIndex,
    required double weight,
    required int reps,
    int? rpe,
    int? rir,
  }) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];

    final newSet = SetRecord(
      weight: weight,
      reps: reps,
      rpe: rpe,
      rir: rir,
      timestamp: DateTime.now(),
    );

    exercises[exerciseIndex] = exercise.copyWith(
      sets: [...exercise.sets, newSet],
    );

    state = state!.copyWith(exercises: exercises);
  }

  /// تعديل ست
  void editSet({
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
    int? rpe,
    int? rir,
  }) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets];

    sets[setIndex] = SetRecord(
      weight: weight,
      reps: reps,
      rpe: rpe,
      rir: rir,
      timestamp: sets[setIndex].timestamp,
    );

    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  /// حذف ست
  void deleteSet({
    required int exerciseIndex,
    required int setIndex,
  }) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets]..removeAt(setIndex);

    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  /// تأشير إحماء كمكتمل
  void markWarmupDone(int warmupIndex, bool done) {
    if (state == null) return;
    final warmups = [...state!.warmups];
    warmups[warmupIndex] = WarmupLog(
      name: warmups[warmupIndex].name,
      reps: warmups[warmupIndex].reps,
      weight: warmups[warmupIndex].weight,
      isDone: done,
    );
    state = state!.copyWith(warmups: warmups);
  }

  /// استخدام بديل
  void useAlternative({
    required int exerciseIndex,
    required String alternative,
  }) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      alternativeUsed: alternative,
    );
    state = state!.copyWith(exercises: exercises);
  }

  /// إضافة ملاحظة على تمرين
  void addExerciseNote({
    required int exerciseIndex,
    required String note,
  }) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(note: note);
    state = state!.copyWith(exercises: exercises);
  }

  /// إنهاء الجلسة وحفظها
  Future<void> finishSession() async {
    if (state == null) return;

    final session = state!.toWorkoutSession();
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final model = WorkoutSessionIsarModel.fromEntity(session);

    await db.writeTxn(() async {
      await db.workoutSessionIsarModels.put(model);

      // حفظ ExerciseLog Index لكل تمرين
      for (final ex in session.exercises) {
        final best = Evaluator.bestSet(ex.sets);
        if (best == null) continue;
        final log = ExerciseLogIsarModel(
          sessionId: session.id,
          userId: session.userId,
          exerciseName: ex.exerciseName,
          dateMs: session.date.millisecondsSinceEpoch,
          bestWeight: best.weight,
          bestReps: best.reps,
          best1RM: Evaluator.epley(best.weight, best.reps),
          totalVolume: Evaluator.volume(ex.sets),
        );
        await db.exerciseLogIsarModels.put(log);
      }
    });

    // مزامنة فورية إذا كان هناك إنترنت
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncLocalChangesToRemote(state!.userId);
    } catch (_) {
      // يُجدَّل للمزامنة في الـ Background
    }

    state = null; // إعادة تعيين الحالة
  }

  /// إلغاء الجلسة
  void cancelSession() => state = null;
}

// ── Evaluator Providers ───────────────────────────────────────

/// تقييم أداء تمرين معين
@riverpod
Future<EvalResult?> exerciseEval(
  ExerciseEvalRef ref,
  ExerciseEvalParams params,
) async {
  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  // جلب آخر 8 جلسات للتمرين المحدد
  final logs = await db.exerciseLogIsarModels
      .filter()
      .userIdEqualTo(params.userId)
      .exerciseNameEqualTo(params.exerciseName)
      .sortByDateMsDesc()
      .limit(8)
      .findAll();

  if (logs.isEmpty) return null;

  final sessions = await db.workoutSessionIsarModels
      .filter()
      .anyOf(logs.map((l) => l.sessionId).toList(),
          (q, id) => q.sessionIdEqualTo(id))
      .sortByDateMsDesc()
      .findAll();

  final entities = sessions.map((s) => s.toEntity()).toList();

  if (entities.isEmpty) return null;

  final current = entities.first;
  final history = entities.skip(1).toList();

  return current.evaluateExercise(
    exerciseName: params.exerciseName,
    history: history,
  );
}

class ExerciseEvalParams {
  const ExerciseEvalParams({
    required this.userId,
    required this.exerciseName,
  });

  final String userId;
  final String exerciseName;

  @override
  bool operator ==(Object other) =>
      other is ExerciseEvalParams &&
      other.userId == userId &&
      other.exerciseName == exerciseName;

  @override
  int get hashCode => Object.hash(userId, exerciseName);
}

// ── Streak Provider ───────────────────────────────────────────

@riverpod
Future<int> currentStreak(CurrentStreakRef ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  final logs = await db.workoutSessionIsarModels
      .filter()
      .userIdEqualTo(user.uid)
      .sortByDateMsDesc()
      .limit(365)
      .findAll();

  if (logs.isEmpty) return 0;

  // حساب الـ Streak: أيام متتالية بدون تفريق
  final today = DateTime.now();
  final dates = logs
      .map((l) => DateTime.fromMillisecondsSinceEpoch(l.dateMs))
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  int streak = 0;
  var current = DateTime(today.year, today.month, today.day);

  for (final date in dates) {
    final diff = current.difference(date).inDays;
    if (diff == 0 || diff == 1) {
      streak++;
      current = date;
    } else {
      break;
    }
  }

  return streak;
}

// ── Helper Classes ────────────────────────────────────────────

class TodayWorkout {
  const TodayWorkout({
    required this.isRestDay,
    required this.sessionName,
    required this.exercises,
    required this.warmups,
    this.previousSession,
  });

  final bool isRestDay;
  final String sessionName;
  final List<ExerciseDefinition> exercises;
  final List<WarmupLog> warmups;
  final WorkoutSession? previousSession;
}

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.sessionId,
    required this.userId,
    required this.sessionName,
    required this.programId,
    required this.startTime,
    required this.exercises,
    required this.warmups,
  });

  final String sessionId;
  final String userId;
  final String sessionName;
  final String programId;
  final DateTime startTime;
  final List<ExerciseState> exercises;
  final List<WarmupLog> warmups;

  WorkoutSessionState copyWith({
    List<ExerciseState>? exercises,
    List<WarmupLog>? warmups,
  }) {
    return WorkoutSessionState(
      sessionId: sessionId,
      userId: userId,
      sessionName: sessionName,
      programId: programId,
      startTime: startTime,
      exercises: exercises ?? this.exercises,
      warmups: warmups ?? this.warmups,
    );
  }

  WorkoutSession toWorkoutSession() {
    final now = DateTime.now();
    return WorkoutSession(
      id: sessionId,
      userId: userId,
      sessionName: sessionName,
      programId: programId,
      date: now,
      exercises: exercises.map((e) => e.toExerciseLog()).toList(),
      warmups: warmups,
      isCompleted: true,
      durationMinutes: now.difference(startTime).inMinutes,
    );
  }
}

class ExerciseState {
  const ExerciseState({
    required this.definition,
    required this.sets,
    this.alternativeUsed = '',
    this.note = '',
  });

  final ExerciseDefinition definition;
  final List<SetRecord> sets;
  final String alternativeUsed;
  final String note;

  factory ExerciseState.fromDefinition(ExerciseDefinition def) {
    return ExerciseState(definition: def, sets: []);
  }

  ExerciseState copyWith({
    List<SetRecord>? sets,
    String? alternativeUsed,
    String? note,
  }) {
    return ExerciseState(
      definition: definition,
      sets: sets ?? this.sets,
      alternativeUsed: alternativeUsed ?? this.alternativeUsed,
      note: note ?? this.note,
    );
  }

  ExerciseLog toExerciseLog() {
    return ExerciseLog(
      exerciseName: alternativeUsed.isNotEmpty
          ? alternativeUsed
          : definition.name,
      sets: sets,
      notes: note,
      alternativeUsed: alternativeUsed,
    );
  }
}

@riverpod
SyncService syncService(SyncServiceRef ref) {
  final gasClient = ref.read(gasClientProvider);
  final isar = ref.read(isarServiceProvider);
  return SyncService(
    gasClient: gasClient,
    isarService: isar,
    connectivity: ref.read(connectivityProvider),
  );
}


@riverpod
Connectivity connectivity(ConnectivityRef ref) => Connectivity();
