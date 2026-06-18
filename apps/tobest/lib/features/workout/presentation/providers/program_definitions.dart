// ============================================================
// TO Best — program_definitions.dart
// تعريفات البرامج التدريبية — مُحوَّلة من config.js
// ============================================================

import 'package:shared/domain/entities/workout_session.dart';

/// تعريفات البرامج التدريبية
///
/// كل برنامج يحتوي على:
/// - أيام التدريب
/// - اسم الجلسة لكل يوم
/// - قائمة التمارين لكل جلسة
class ProgramDefinitions {
  ProgramDefinitions._();

  // ── البرامج المدعومة ──────────────────────────────────────
  static const Map<String, String> programNames = {
    'AP': 'Anterior + Posterior',
    'PPL': 'Push Pull Legs',
    'UL': 'Upper Lower',
    'FB': 'Full Body',
    'CARDIO': 'Cardio',
    'REHAB': 'Rehab',
    'WL': 'Weight Loss',
    'HYP': 'Hypertrophy',
  };

  /// الحصول على الجلسة المقررة لليوم
  ///
  /// [program] اسم البرنامج
  /// [programDays] عدد أيام التدريب في الأسبوع
  static TodaySession? getTodaySession({
    required String program,
    required int programDays,
  }) {
    final weekday = DateTime.now().weekday; // 1=Mon, 7=Sun

    return switch (program) {
      'AP' => _getAPSession(weekday, programDays),
      'PPL' => _getPPLSession(weekday, programDays),
      'UL' => _getULSession(weekday, programDays),
      'FB' => _getFBSession(weekday, programDays),
      'CARDIO' => _getCardioSession(weekday),
      'WL' => _getWLSession(weekday, programDays),
      'HYP' => _getHYPSession(weekday, programDays),
      _ => null,
    };
  }

  // ── AP — Anterior + Posterior ─────────────────────────────

  static TodaySession? _getAPSession(int weekday, int days) {
    // 4 أيام: Mon, Wed, Thu, Sat
    // 5 أيام: Mon, Tue, Thu, Fri, Sat
    final schedule4 = {1: 'A-ANT', 3: 'A-POST', 4: 'B-ANT', 6: 'B-POST'};
    final schedule5 = {
      1: 'A-ANT',
      2: 'A-POST',
      4: 'B-ANT',
      5: 'B-POST',
      6: 'C-ANT',
    };

    final schedule = days >= 5 ? schedule5 : schedule4;
    final sessionName = schedule[weekday];
    if (sessionName == null) return null; // يوم راحة

    return TodaySession(
      name: sessionName,
      exercises: _apExercises[sessionName] ?? [],
      warmups: _apWarmups[sessionName] ?? [],
    );
  }

  // ── PPL — Push Pull Legs ─────────────────────────────────

  static TodaySession? _getPPLSession(int weekday, int days) {
    final schedule3 = {1: 'PUSH', 3: 'PULL', 5: 'LEGS'};
    final schedule6 = {
      1: 'PUSH-A',
      2: 'PULL-A',
      3: 'LEGS-A',
      5: 'PUSH-B',
      6: 'PULL-B',
      7: 'LEGS-B',
    };

    final schedule = days >= 6 ? schedule6 : schedule3;
    final sessionName = schedule[weekday];
    if (sessionName == null) return null;

    return TodaySession(
      name: sessionName,
      exercises: _pplExercises[sessionName] ?? [],
      warmups: _pplWarmups[sessionName] ?? [],
    );
  }

  // ── UL — Upper Lower ─────────────────────────────────────

  static TodaySession? _getULSession(int weekday, int days) {
    final schedule4 = {1: 'UPPER-A', 2: 'LOWER-A', 4: 'UPPER-B', 5: 'LOWER-B'};
    final schedule = schedule4;
    final sessionName = schedule[weekday];
    if (sessionName == null) return null;

    return TodaySession(
      name: sessionName,
      exercises: _ulExercises[sessionName] ?? [],
      warmups: _ulWarmups[sessionName] ?? [],
    );
  }

  // ── FB — Full Body ────────────────────────────────────────

  static TodaySession? _getFBSession(int weekday, int days) {
    final schedule3 = {1: 'FB-A', 3: 'FB-B', 5: 'FB-C'};
    final sessionName = schedule3[weekday];
    if (sessionName == null) return null;

    return TodaySession(
      name: sessionName,
      exercises: _fbExercises[sessionName] ?? [],
      warmups: const [],
    );
  }

  // ── Cardio ────────────────────────────────────────────────

  static TodaySession? _getCardioSession(int weekday) {
    if (weekday == 7) return null; // الأحد راحة
    return TodaySession(
      name: 'CARDIO',
      exercises: _cardioExercises,
      warmups: const [],
    );
  }

  // ── WL — Weight Loss ─────────────────────────────────────

  static TodaySession? _getWLSession(int weekday, int days) {
    final schedule4 = {1: 'WL-ST-A', 2: 'WL-CARDIO', 4: 'WL-ST-B', 5: 'WL-CARDIO'};
    final sessionName = schedule4[weekday];
    if (sessionName == null) return null;

    return TodaySession(
      name: sessionName,
      exercises: _wlExercises[sessionName] ?? [],
      warmups: const [],
    );
  }

  // ── HYP — Hypertrophy ────────────────────────────────────

  static TodaySession? _getHYPSession(int weekday, int days) {
    final schedule4 = {1: 'HYP-CHEST', 2: 'HYP-BACK', 4: 'HYP-LEGS', 5: 'HYP-SHOULDERS'};
    final sessionName = schedule4[weekday];
    if (sessionName == null) return null;

    return TodaySession(
      name: sessionName,
      exercises: _hypExercises[sessionName] ?? [],
      warmups: const [],
    );
  }

  // ── تعريفات التمارين ─────────────────────────────────────

  static const Map<String, List<ExerciseDefinition>> _apExercises = {
    'A-ANT': [
      ExerciseDefinition(
        name: 'Barbell Back Squat',
        isPrimary: true,
        sets: 4,
        reps: '5~7',
        rest: '3~5',
        muscle: 'Quads',
        warmupSets: '2',
        alt1: 'Leg Press',
        alt2: 'Hack Squat',
      ),
      ExerciseDefinition(
        name: 'Bulgarian Split Squat',
        isPrimary: true,
        sets: 3,
        reps: '8~10',
        rest: '2~3',
        muscle: 'Quads',
        alt1: 'Lunges',
        alt2: 'Step Up',
      ),
      ExerciseDefinition(
        name: 'Leg Extension',
        isPrimary: false,
        sets: 3,
        reps: '10~15',
        rest: '1~2',
        muscle: 'Quads',
        alt1: 'Wall Sit',
      ),
      ExerciseDefinition(
        name: 'Incline Bench Press',
        isPrimary: true,
        sets: 4,
        reps: '6~8',
        rest: '3~4',
        muscle: 'Upper Chest',
        warmupSets: '2',
        alt1: 'Incline DB Press',
        alt2: 'Machine Chest Press',
      ),
      ExerciseDefinition(
        name: 'Cable Lateral Raise',
        isPrimary: false,
        sets: 3,
        reps: '12~15',
        rest: '1~2',
        muscle: 'Side Delts',
        alt1: 'DB Lateral Raise',
      ),
      ExerciseDefinition(
        name: 'Tricep Pushdown',
        isPrimary: false,
        sets: 3,
        reps: '10~12',
        rest: '1~2',
        muscle: 'Triceps',
        alt1: 'Dip',
        alt2: 'Skull Crusher',
      ),
    ],
    'A-POST': [
      ExerciseDefinition(
        name: 'Romanian Deadlift',
        isPrimary: true,
        sets: 4,
        reps: '6~8',
        rest: '3~5',
        muscle: 'Hamstrings',
        warmupSets: '2',
        alt1: 'Stiff-Leg Deadlift',
        alt2: 'Good Morning',
      ),
      ExerciseDefinition(
        name: 'Lying Leg Curl',
        isPrimary: true,
        sets: 3,
        reps: '8~12',
        rest: '2~3',
        muscle: 'Hamstrings',
        alt1: 'Nordic Curl',
        alt2: 'Seated Leg Curl',
      ),
      ExerciseDefinition(
        name: 'Barbell Hip Thrust',
        isPrimary: true,
        sets: 4,
        reps: '8~12',
        rest: '2~3',
        muscle: 'Glutes',
        alt1: 'Cable Pull-Through',
        alt2: 'Glute Bridge',
      ),
      ExerciseDefinition(
        name: 'Weighted Pull-Up',
        isPrimary: true,
        sets: 4,
        reps: '5~8',
        rest: '3~5',
        muscle: 'Back Width',
        warmupSets: '1',
        alt1: 'Lat Pulldown',
        alt2: 'Assisted Pull-Up',
      ),
      ExerciseDefinition(
        name: 'Pendlay Row',
        isPrimary: true,
        sets: 3,
        reps: '6~8',
        rest: '3~4',
        muscle: 'Back Thickness',
        alt1: 'Barbell Row',
        alt2: 'DB Row',
      ),
      ExerciseDefinition(
        name: 'Barbell Curl',
        isPrimary: false,
        sets: 3,
        reps: '8~12',
        rest: '1~2',
        muscle: 'Biceps',
        alt1: 'DB Curl',
        alt2: 'Cable Curl',
      ),
    ],
    'B-ANT': [
      ExerciseDefinition(
        name: 'Hack Squat',
        isPrimary: true,
        sets: 4,
        reps: '8~10',
        rest: '3~4',
        muscle: 'Quads',
        warmupSets: '1',
        alt1: 'Leg Press',
        alt2: 'Smith Machine Squat',
      ),
      ExerciseDefinition(
        name: 'Front Squat',
        isPrimary: true,
        sets: 3,
        reps: '6~8',
        rest: '3~5',
        muscle: 'Quads',
        alt1: 'Goblet Squat',
        alt2: 'DB Front Squat',
      ),
      ExerciseDefinition(
        name: 'Flat Bench Press',
        isPrimary: true,
        sets: 4,
        reps: '6~8',
        rest: '3~5',
        muscle: 'Chest',
        warmupSets: '2',
        alt1: 'DB Bench Press',
        alt2: 'Smith Machine Press',
      ),
      ExerciseDefinition(
        name: 'Cable Fly',
        isPrimary: false,
        sets: 3,
        reps: '12~15',
        rest: '1~2',
        muscle: 'Chest',
        alt1: 'Pec Deck',
        alt2: 'DB Fly',
      ),
      ExerciseDefinition(
        name: 'OHP',
        isPrimary: true,
        sets: 4,
        reps: '6~8',
        rest: '3~4',
        muscle: 'Shoulders',
        warmupSets: '1',
        alt1: 'DB Press',
        alt2: 'Machine Press',
      ),
      ExerciseDefinition(
        name: 'Overhead Tricep Extension',
        isPrimary: false,
        sets: 3,
        reps: '10~15',
        rest: '1~2',
        muscle: 'Triceps',
        alt1: 'Skull Crusher',
        alt2: 'Rope Extension',
      ),
    ],
    'B-POST': [
      ExerciseDefinition(
        name: 'Conventional Deadlift',
        isPrimary: true,
        sets: 4,
        reps: '4~6',
        rest: '4~5',
        muscle: 'Full Posterior',
        warmupSets: '3',
        alt1: 'Trap Bar Deadlift',
        alt2: 'Sumo Deadlift',
      ),
      ExerciseDefinition(
        name: 'Cable Kickback',
        isPrimary: false,
        sets: 3,
        reps: '12~15',
        rest: '1~2',
        muscle: 'Glutes',
        alt1: 'Donkey Kick',
      ),
      ExerciseDefinition(
        name: 'Seated Cable Row',
        isPrimary: true,
        sets: 4,
        reps: '8~10',
        rest: '2~3',
        muscle: 'Back Thickness',
        alt1: 'Machine Row',
        alt2: 'Chest-Supported Row',
      ),
      ExerciseDefinition(
        name: 'Lat Pulldown',
        isPrimary: true,
        sets: 3,
        reps: '8~12',
        rest: '2~3',
        muscle: 'Back Width',
        alt1: 'Assisted Pull-Up',
        alt2: 'Machine Pulldown',
      ),
      ExerciseDefinition(
        name: 'Face Pull',
        isPrimary: false,
        sets: 3,
        reps: '12~15',
        rest: '1~2',
        muscle: 'Rear Delts',
        alt1: 'Band Pull-Apart',
        alt2: 'Reverse Fly',
      ),
      ExerciseDefinition(
        name: 'Hammer Curl',
        isPrimary: false,
        sets: 3,
        reps: '10~12',
        rest: '1~2',
        muscle: 'Biceps',
        alt1: 'Rope Curl',
        alt2: 'Cross-Body Curl',
      ),
    ],
  };

  // PPL Exercises (مبسّطة)
  static const Map<String, List<ExerciseDefinition>> _pplExercises = {
    'PUSH': [
      ExerciseDefinition(
        name: 'Flat Bench Press',
        isPrimary: true, sets: 4, reps: '5~7', rest: '3~5', muscle: 'Chest',
        warmupSets: '2', alt1: 'DB Bench Press', alt2: 'Machine Press',
      ),
      ExerciseDefinition(
        name: 'OHP', isPrimary: true, sets: 4, reps: '6~8', rest: '3~4',
        muscle: 'Shoulders', alt1: 'DB Press', alt2: 'Smith Machine',
      ),
      ExerciseDefinition(
        name: 'Incline DB Press', isPrimary: false, sets: 3, reps: '8~12',
        rest: '2~3', muscle: 'Upper Chest', alt1: 'Incline Barbell Press',
      ),
      ExerciseDefinition(
        name: 'Cable Lateral Raise', isPrimary: false, sets: 4, reps: '12~15',
        rest: '1~2', muscle: 'Side Delts', alt1: 'DB Lateral Raise',
      ),
      ExerciseDefinition(
        name: 'Tricep Pushdown', isPrimary: false, sets: 3, reps: '10~15',
        rest: '1~2', muscle: 'Triceps', alt1: 'Rope Pushdown', alt2: 'Dip',
      ),
    ],
    'PULL': [
      ExerciseDefinition(
        name: 'Weighted Pull-Up', isPrimary: true, sets: 4, reps: '5~8',
        rest: '3~5', muscle: 'Back Width', alt1: 'Lat Pulldown',
      ),
      ExerciseDefinition(
        name: 'Barbell Row', isPrimary: true, sets: 4, reps: '6~8',
        rest: '3~4', muscle: 'Back Thickness', alt1: 'DB Row', alt2: 'Cable Row',
      ),
      ExerciseDefinition(
        name: 'Face Pull', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Rear Delts', alt1: 'Reverse Fly',
      ),
      ExerciseDefinition(
        name: 'Barbell Curl', isPrimary: false, sets: 3, reps: '8~12',
        rest: '1~2', muscle: 'Biceps', alt1: 'DB Curl', alt2: 'Cable Curl',
      ),
      ExerciseDefinition(
        name: 'Hammer Curl', isPrimary: false, sets: 3, reps: '10~12',
        rest: '1~2', muscle: 'Brachialis', alt1: 'Rope Curl',
      ),
    ],
    'LEGS': [
      ExerciseDefinition(
        name: 'Barbell Back Squat', isPrimary: true, sets: 4, reps: '5~7',
        rest: '3~5', muscle: 'Quads', warmupSets: '2', alt1: 'Leg Press',
      ),
      ExerciseDefinition(
        name: 'Romanian Deadlift', isPrimary: true, sets: 4, reps: '8~10',
        rest: '3~4', muscle: 'Hamstrings', alt1: 'Leg Curl',
      ),
      ExerciseDefinition(
        name: 'Leg Press', isPrimary: false, sets: 3, reps: '10~15',
        rest: '2~3', muscle: 'Quads', alt1: 'Hack Squat',
      ),
      ExerciseDefinition(
        name: 'Barbell Hip Thrust', isPrimary: true, sets: 4, reps: '10~12',
        rest: '2~3', muscle: 'Glutes', alt1: 'Cable Pull-Through',
      ),
      ExerciseDefinition(
        name: 'Calf Raise', isPrimary: false, sets: 4, reps: '15~20',
        rest: '1', muscle: 'Calves', alt1: 'Seated Calf Raise',
      ),
    ],
  };

  // UL, FB, WL, HYP Exercises (مبسّطة للاختصار — نفس النمط)
  static const Map<String, List<ExerciseDefinition>> _ulExercises = {
    'UPPER-A': [
      ExerciseDefinition(
        name: 'Flat Bench Press', isPrimary: true, sets: 4, reps: '5~7',
        rest: '3~5', muscle: 'Chest', warmupSets: '2', alt1: 'DB Press',
      ),
      ExerciseDefinition(
        name: 'Weighted Pull-Up', isPrimary: true, sets: 4, reps: '5~8',
        rest: '3~5', muscle: 'Back', alt1: 'Lat Pulldown',
      ),
      ExerciseDefinition(
        name: 'OHP', isPrimary: true, sets: 3, reps: '6~8', rest: '3~4',
        muscle: 'Shoulders', alt1: 'DB Press',
      ),
      ExerciseDefinition(
        name: 'DB Row', isPrimary: false, sets: 3, reps: '8~12', rest: '2~3',
        muscle: 'Back', alt1: 'Cable Row',
      ),
      ExerciseDefinition(
        name: 'Barbell Curl', isPrimary: false, sets: 3, reps: '8~12',
        rest: '1~2', muscle: 'Biceps', alt1: 'DB Curl',
      ),
      ExerciseDefinition(
        name: 'Tricep Pushdown', isPrimary: false, sets: 3, reps: '10~15',
        rest: '1~2', muscle: 'Triceps', alt1: 'Dip',
      ),
    ],
    'LOWER-A': [
      ExerciseDefinition(
        name: 'Barbell Back Squat', isPrimary: true, sets: 4, reps: '5~7',
        rest: '3~5', muscle: 'Quads', warmupSets: '2', alt1: 'Leg Press',
      ),
      ExerciseDefinition(
        name: 'Romanian Deadlift', isPrimary: true, sets: 4, reps: '8~10',
        rest: '3~4', muscle: 'Hamstrings', alt1: 'Leg Curl',
      ),
      ExerciseDefinition(
        name: 'Leg Press', isPrimary: false, sets: 3, reps: '12~15',
        rest: '2~3', muscle: 'Quads', alt1: 'Hack Squat',
      ),
      ExerciseDefinition(
        name: 'Hip Thrust', isPrimary: true, sets: 3, reps: '10~12',
        rest: '2~3', muscle: 'Glutes', alt1: 'Cable Pull-Through',
      ),
    ],
    'UPPER-B': [
      ExerciseDefinition(
        name: 'Incline Bench Press', isPrimary: true, sets: 4, reps: '6~8',
        rest: '3~4', muscle: 'Upper Chest', warmupSets: '1', alt1: 'Incline DB Press',
      ),
      ExerciseDefinition(
        name: 'Seated Cable Row', isPrimary: true, sets: 4, reps: '8~10',
        rest: '2~3', muscle: 'Back', alt1: 'Machine Row',
      ),
      ExerciseDefinition(
        name: 'DB Lateral Raise', isPrimary: false, sets: 4, reps: '12~15',
        rest: '1~2', muscle: 'Side Delts', alt1: 'Cable Lateral',
      ),
      ExerciseDefinition(
        name: 'Face Pull', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Rear Delts', alt1: 'Reverse Fly',
      ),
      ExerciseDefinition(
        name: 'Hammer Curl', isPrimary: false, sets: 3, reps: '10~12',
        rest: '1~2', muscle: 'Biceps', alt1: 'DB Curl',
      ),
    ],
    'LOWER-B': [
      ExerciseDefinition(
        name: 'Conventional Deadlift', isPrimary: true, sets: 4, reps: '4~6',
        rest: '4~5', muscle: 'Full Posterior', warmupSets: '3', alt1: 'Trap Bar DL',
      ),
      ExerciseDefinition(
        name: 'Bulgarian Split Squat', isPrimary: true, sets: 3, reps: '8~10',
        rest: '2~3', muscle: 'Quads', alt1: 'Lunges',
      ),
      ExerciseDefinition(
        name: 'Lying Leg Curl', isPrimary: false, sets: 3, reps: '10~12',
        rest: '1~2', muscle: 'Hamstrings', alt1: 'Nordic Curl',
      ),
      ExerciseDefinition(
        name: 'Calf Raise', isPrimary: false, sets: 4, reps: '15~20',
        rest: '1', muscle: 'Calves', alt1: 'Seated Calf Raise',
      ),
    ],
  };

  static const Map<String, List<ExerciseDefinition>> _fbExercises = {
    'FB-A': [
      ExerciseDefinition(
        name: 'Barbell Back Squat', isPrimary: true, sets: 3, reps: '6~8',
        rest: '3~5', muscle: 'Quads', warmupSets: '1', alt1: 'Leg Press',
      ),
      ExerciseDefinition(
        name: 'Flat Bench Press', isPrimary: true, sets: 3, reps: '6~8',
        rest: '3~4', muscle: 'Chest', alt1: 'DB Press',
      ),
      ExerciseDefinition(
        name: 'Weighted Pull-Up', isPrimary: true, sets: 3, reps: '6~8',
        rest: '3~4', muscle: 'Back', alt1: 'Lat Pulldown',
      ),
      ExerciseDefinition(
        name: 'OHP', isPrimary: false, sets: 2, reps: '8~10',
        rest: '2~3', muscle: 'Shoulders', alt1: 'DB Press',
      ),
    ],
    'FB-B': [
      ExerciseDefinition(
        name: 'Romanian Deadlift', isPrimary: true, sets: 3, reps: '8~10',
        rest: '3~4', muscle: 'Hamstrings', alt1: 'Leg Curl',
      ),
      ExerciseDefinition(
        name: 'Incline DB Press', isPrimary: true, sets: 3, reps: '8~12',
        rest: '3~4', muscle: 'Upper Chest', alt1: 'Machine Press',
      ),
      ExerciseDefinition(
        name: 'DB Row', isPrimary: true, sets: 3, reps: '8~12', rest: '2~3',
        muscle: 'Back', alt1: 'Cable Row',
      ),
      ExerciseDefinition(
        name: 'DB Lateral Raise', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Side Delts', alt1: 'Cable Lateral',
      ),
    ],
    'FB-C': [
      ExerciseDefinition(
        name: 'Leg Press', isPrimary: true, sets: 4, reps: '10~15',
        rest: '2~3', muscle: 'Quads', alt1: 'Hack Squat',
      ),
      ExerciseDefinition(
        name: 'Cable Fly', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Chest', alt1: 'Pec Deck',
      ),
      ExerciseDefinition(
        name: 'Lat Pulldown', isPrimary: false, sets: 3, reps: '10~12',
        rest: '2~3', muscle: 'Back', alt1: 'Machine Pulldown',
      ),
      ExerciseDefinition(
        name: 'Barbell Curl', isPrimary: false, sets: 3, reps: '10~12',
        rest: '1~2', muscle: 'Biceps', alt1: 'DB Curl',
      ),
      ExerciseDefinition(
        name: 'Tricep Pushdown', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Triceps', alt1: 'Rope Pushdown',
      ),
    ],
  };

  static const List<ExerciseDefinition> _cardioExercises = [
    ExerciseDefinition(
      name: 'Treadmill Walk', isPrimary: true, sets: 1, reps: '20~40 min',
      rest: '0', muscle: 'Cardio',
    ),
    ExerciseDefinition(
      name: 'Stationary Bike', isPrimary: false, sets: 1, reps: '15~30 min',
      rest: '0', muscle: 'Cardio', alt1: 'Elliptical',
    ),
  ];

  static const Map<String, List<ExerciseDefinition>> _wlExercises = {
    'WL-ST-A': [
      ExerciseDefinition(
        name: 'Goblet Squat', isPrimary: true, sets: 3, reps: '12~15',
        rest: '2~3', muscle: 'Quads', alt1: 'Leg Press',
      ),
      ExerciseDefinition(
        name: 'DB Bench Press', isPrimary: true, sets: 3, reps: '10~15',
        rest: '2~3', muscle: 'Chest', alt1: 'Machine Press',
      ),
      ExerciseDefinition(
        name: 'Lat Pulldown', isPrimary: true, sets: 3, reps: '10~15',
        rest: '2~3', muscle: 'Back', alt1: 'Assisted Pull-Up',
      ),
      ExerciseDefinition(
        name: 'Plank', isPrimary: false, sets: 3, reps: '30~60 sec',
        rest: '1', muscle: 'Core',
      ),
    ],
    'WL-CARDIO': [
      ExerciseDefinition(
        name: 'Treadmill Incline Walk', isPrimary: true, sets: 1,
        reps: '30~45 min', rest: '0', muscle: 'Cardio',
      ),
    ],
  };

  static const Map<String, List<ExerciseDefinition>> _hypExercises = {
    'HYP-CHEST': [
      ExerciseDefinition(
        name: 'Flat Bench Press', isPrimary: true, sets: 4, reps: '8~12',
        rest: '2~3', muscle: 'Chest', warmupSets: '1', alt1: 'DB Press',
      ),
      ExerciseDefinition(
        name: 'Incline DB Press', isPrimary: true, sets: 4, reps: '10~15',
        rest: '2~3', muscle: 'Upper Chest', alt1: 'Cable Press',
      ),
      ExerciseDefinition(
        name: 'Cable Fly', isPrimary: false, sets: 3, reps: '12~20',
        rest: '1~2', muscle: 'Chest', alt1: 'Pec Deck',
      ),
      ExerciseDefinition(
        name: 'Tricep Pushdown', isPrimary: false, sets: 4, reps: '12~15',
        rest: '1~2', muscle: 'Triceps', alt1: 'Overhead Extension',
      ),
    ],
    'HYP-BACK': [
      ExerciseDefinition(
        name: 'Lat Pulldown', isPrimary: true, sets: 4, reps: '8~12',
        rest: '2~3', muscle: 'Back Width', alt1: 'Pull-Up',
      ),
      ExerciseDefinition(
        name: 'Seated Cable Row', isPrimary: true, sets: 4, reps: '10~12',
        rest: '2~3', muscle: 'Back Thickness', alt1: 'Machine Row',
      ),
      ExerciseDefinition(
        name: 'DB Row', isPrimary: false, sets: 3, reps: '10~15',
        rest: '2~3', muscle: 'Back', alt1: 'Chest-Supported Row',
      ),
      ExerciseDefinition(
        name: 'Barbell Curl', isPrimary: false, sets: 4, reps: '10~15',
        rest: '1~2', muscle: 'Biceps', alt1: 'DB Curl',
      ),
    ],
    'HYP-LEGS': [
      ExerciseDefinition(
        name: 'Leg Press', isPrimary: true, sets: 4, reps: '10~15',
        rest: '2~3', muscle: 'Quads', warmupSets: '1', alt1: 'Hack Squat',
      ),
      ExerciseDefinition(
        name: 'Romanian Deadlift', isPrimary: true, sets: 4, reps: '10~12',
        rest: '2~3', muscle: 'Hamstrings', alt1: 'Leg Curl',
      ),
      ExerciseDefinition(
        name: 'Lying Leg Curl', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Hamstrings', alt1: 'Nordic Curl',
      ),
      ExerciseDefinition(
        name: 'Hip Thrust', isPrimary: false, sets: 4, reps: '12~15',
        rest: '2', muscle: 'Glutes', alt1: 'Cable Pull-Through',
      ),
      ExerciseDefinition(
        name: 'Calf Raise', isPrimary: false, sets: 4, reps: '15~25',
        rest: '1', muscle: 'Calves',
      ),
    ],
    'HYP-SHOULDERS': [
      ExerciseDefinition(
        name: 'DB Shoulder Press', isPrimary: true, sets: 4, reps: '10~15',
        rest: '2~3', muscle: 'Front Delts', alt1: 'Machine Press',
      ),
      ExerciseDefinition(
        name: 'DB Lateral Raise', isPrimary: true, sets: 5, reps: '12~20',
        rest: '1~2', muscle: 'Side Delts', alt1: 'Cable Lateral',
      ),
      ExerciseDefinition(
        name: 'Face Pull', isPrimary: false, sets: 4, reps: '12~20',
        rest: '1~2', muscle: 'Rear Delts', alt1: 'Reverse Fly',
      ),
      ExerciseDefinition(
        name: 'Hammer Curl', isPrimary: false, sets: 3, reps: '12~15',
        rest: '1~2', muscle: 'Biceps', alt1: 'DB Curl',
      ),
    ],
  };

  // ── Warmups ───────────────────────────────────────────────
  static const Map<String, List<WarmupLog>> _apWarmups = {
    'A-ANT': [
      WarmupLog(name: 'Leg Swing Forward', reps: '10 each'),
      WarmupLog(name: 'Hip Circle', reps: '10 each'),
      WarmupLog(name: 'Body Weight Squat', reps: '15'),
      WarmupLog(name: 'Arm Circle', reps: '10 each'),
      WarmupLog(name: 'Band Pull-Apart', reps: '20'),
    ],
    'A-POST': [
      WarmupLog(name: 'Cat-Cow', reps: '10'),
      WarmupLog(name: 'Hip Hinge', reps: '10'),
      WarmupLog(name: 'Glute Bridge', reps: '15'),
      WarmupLog(name: 'Band Pull-Apart', reps: '20'),
    ],
    'B-ANT': [
      WarmupLog(name: 'Leg Swing Lateral', reps: '10 each'),
      WarmupLog(name: 'Body Weight Squat', reps: '15'),
      WarmupLog(name: 'Push-Up', reps: '10'),
      WarmupLog(name: 'Shoulder Circle', reps: '10 each'),
    ],
    'B-POST': [
      WarmupLog(name: 'Hip Hinge', reps: '10'),
      WarmupLog(name: 'Glute Bridge', reps: '15'),
      WarmupLog(name: 'Face Pull Light', reps: '15'),
      WarmupLog(name: 'Band Row', reps: '15'),
    ],
  };

  static const Map<String, List<WarmupLog>> _pplWarmups = {
    'PUSH': [
      WarmupLog(name: 'Push-Up', reps: '10'),
      WarmupLog(name: 'Shoulder Circle', reps: '10 each'),
      WarmupLog(name: 'Band Pull-Apart', reps: '20'),
    ],
    'PULL': [
      WarmupLog(name: 'Band Pull-Apart', reps: '20'),
      WarmupLog(name: 'Dead Hang', reps: '30 sec'),
      WarmupLog(name: 'Face Pull Light', reps: '15'),
    ],
    'LEGS': [
      WarmupLog(name: 'Hip Circle', reps: '10 each'),
      WarmupLog(name: 'Body Weight Squat', reps: '15'),
      WarmupLog(name: 'Glute Bridge', reps: '15'),
    ],
  };

  static const Map<String, List<WarmupLog>> _ulWarmups = {
    'UPPER-A': [
      WarmupLog(name: 'Push-Up', reps: '10'),
      WarmupLog(name: 'Band Pull-Apart', reps: '20'),
      WarmupLog(name: 'Shoulder Circle', reps: '10 each'),
    ],
    'LOWER-A': [
      WarmupLog(name: 'Body Weight Squat', reps: '15'),
      WarmupLog(name: 'Hip Circle', reps: '10 each'),
      WarmupLog(name: 'Glute Bridge', reps: '15'),
    ],
    'UPPER-B': [
      WarmupLog(name: 'Push-Up', reps: '10'),
      WarmupLog(name: 'Dead Hang', reps: '30 sec'),
      WarmupLog(name: 'Band Pull-Apart', reps: '20'),
    ],
    'LOWER-B': [
      WarmupLog(name: 'Hip Hinge', reps: '10'),
      WarmupLog(name: 'Glute Bridge', reps: '15'),
      WarmupLog(name: 'Body Weight Squat', reps: '10'),
    ],
  };
}

/// جلسة اليوم
class TodaySession {
  const TodaySession({
    required this.name,
    required this.exercises,
    required this.warmups,
  });

  final String name;
  final List<ExerciseDefinition> exercises;
  final List<WarmupLog> warmups;
}
