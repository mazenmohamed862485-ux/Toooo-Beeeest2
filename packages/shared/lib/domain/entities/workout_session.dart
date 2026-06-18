// ============================================================
// TO Best — domain/entities/workout_session.dart
// كيانات التمرين في طبقة Domain
// ============================================================

import 'package:equatable/equatable.dart';

/// جلسة تمرين كاملة
class WorkoutSession extends Equatable {
  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.sessionName,
    required this.programId,
    required this.date,
    required this.exercises,
    this.warmups = const [],
    this.isCompleted = false,
    this.durationMinutes = 0,
    this.notes = '',
  });

  final String id;
  final String userId;

  /// اسم الجلسة (مثل: Anterior A)
  final String sessionName;

  /// اسم البرنامج (مثل: AP)
  final String programId;

  final DateTime date;
  final List<ExerciseLog> exercises;
  final List<WarmupLog> warmups;
  final bool isCompleted;

  /// مدة الجلسة بالدقائق
  final int durationMinutes;

  final String notes;

  @override
  List<Object?> get props => [id, userId, date, sessionName];

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? sessionName,
    String? programId,
    DateTime? date,
    List<ExerciseLog>? exercises,
    List<WarmupLog>? warmups,
    bool? isCompleted,
    int? durationMinutes,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionName: sessionName ?? this.sessionName,
      programId: programId ?? this.programId,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      warmups: warmups ?? this.warmups,
      isCompleted: isCompleted ?? this.isCompleted,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
    );
  }
}

/// سجل تمرين واحد داخل الجلسة
class ExerciseLog extends Equatable {
  const ExerciseLog({
    required this.exerciseName,
    required this.sets,
    this.notes = '',
    this.alternativeUsed = '',
    this.updatedAt,
  });

  final String exerciseName;
  final List<SetRecord> sets;
  final String notes;

  /// البديل المستخدم (إن وجد)
  final String alternativeUsed;

  final DateTime? updatedAt;

  @override
  List<Object?> get props => [exerciseName, sets];
}

/// سجل ست واحد
class SetRecord extends Equatable {
  const SetRecord({
    required this.weight,
    required this.reps,
    this.rpe,
    this.rir,
    this.isWarmup = false,
    this.timestamp,
  });

  /// الوزن بالكيلوغرام
  final double weight;

  /// عدد التكرارات
  final int reps;

  /// Rate of Perceived Exertion (1-10)
  final int? rpe;

  /// Reps in Reserve (0-4)
  final int? rir;

  final bool isWarmup;
  final DateTime? timestamp;

  @override
  List<Object?> get props => [weight, reps, rpe, rir];
}

/// سجل تمرين إحماء
class WarmupLog extends Equatable {
  const WarmupLog({
    required this.name,
    required this.reps,
    this.weight = 0,
    this.isDone = false,
  });

  final String name;
  final String reps;
  final double weight;
  final bool isDone;

  @override
  List<Object?> get props => [name, isDone];
}

/// تمرين من البرنامج المُحدَّد
class ExerciseDefinition extends Equatable {
  const ExerciseDefinition({
    required this.name,
    required this.isPrimary,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.muscle,
    this.warmupSets = '0',
    this.alt1 = '',
    this.alt2 = '',
    this.note = '',
    this.videoIds = const [],
  });

  final String name;
  final bool isPrimary;

  /// عدد السيتات (كرقم)
  final int sets;

  /// نطاق التكرارات (مثل: "6~8")
  final String reps;

  /// نطاق الراحة (مثل: "3~5")
  final String rest;

  /// العضلة المستهدفة
  final String muscle;

  final String warmupSets;
  final String alt1;
  final String alt2;
  final String note;

  /// معرّفات الفيديوهات لهذا التمرين
  final List<String> videoIds;

  @override
  List<Object?> get props => [name];
}

/// نتيجة تقييم الأداء (من evaluator.dart)
class EvalResult extends Equatable {
  const EvalResult({
    required this.code,
    required this.arabicLabel,
    required this.englishLabel,
    required this.icon,
  });

  /// كود التقييم (s1, s2, s3, rv, gd, st, ws, dn, beg)
  final String code;

  final String arabicLabel;
  final String englishLabel;

  /// اسم الأيقونة (Material Icons)
  final String icon;

  @override
  List<Object?> get props => [code];
}

/// اقتراح التكرارات (زيادة/تخفيض الوزن)
class RepSuggestion extends Equatable {
  const RepSuggestion({
    required this.type,
    required this.arabicText,
    required this.englishText,
  });

  /// up / down
  final String type;

  final String arabicText;
  final String englishText;

  @override
  List<Object?> get props => [type];
}

/// طلب تغيير/إضافة برنامج
class ProgramChangeRequest extends Equatable {
  const ProgramChangeRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.requestType,
    required this.requestedProgram,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.responseNote = '',
    this.respondedAt,
  });

  final String id;
  final String userId;
  final String userName;

  /// 'change' / 'add' (إضافة كارديو مثلاً)
  final String requestType;

  final String requestedProgram;
  final String reason;

  /// pending / approved / rejected
  final String status;

  final DateTime createdAt;
  final String responseNote;
  final DateTime? respondedAt;

  @override
  List<Object?> get props => [id, status];
}
