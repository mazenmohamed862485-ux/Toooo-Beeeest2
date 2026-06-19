// TO Best — domain/repositories/workout_repository.dart

import '../entities/workout_session.dart';

abstract class WorkoutRepository {
  Future<List<WorkoutSession>> getWorkoutSessions({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  Future<void> saveWorkoutSession(WorkoutSession session);

  Future<List<WorkoutSession>> getExerciseHistory({
    required String userId,
    required String exerciseName,
    int limit,
  });

  Future<List<ExerciseDefinition>> getSessionExercises({
    required String programId,
    required String sessionName,
    required String userId,
  });

  Future<void> saveProgramChangeRequest(ProgramChangeRequest request);
  Future<void> syncWorkoutsToRemote(String userId);
  Future<int> getCurrentStreak(String userId);

  Future<Map<DateTime, bool>> getMonthlyActivity({
    required String userId,
    required int year,
    required int month,
  });
}
