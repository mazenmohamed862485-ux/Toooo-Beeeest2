// ============================================================
// TO Best — utils/evaluator.dart
// محرك تقييم الأداء + حسابات التغذية
// ترجمة حرفية من evaluator.js — لا تعديل على المنطق
// ============================================================

import 'dart:math';
import '../domain/entities/workout_session.dart';
import '../domain/entities/nutrition.dart';
import '../domain/entities/user.dart';

/// محرك تقييم أداء التمرين وحسابات التغذية
///
/// ترجمة حرفية من evaluator.js — كل الدوال محوَّلة بدون تغيير منطقي
class Evaluator {
  Evaluator._();

  // ── ثوابت التقييم ────────────────────────────────────────
  /// عدد التكرارات الذي يستدعي زيادة الوزن
  static const int upThreshold = 12;

  /// عدد التكرارات الذي يستدعي تخفيض الوزن
  static const int downThreshold = 4;

  /// عدد الأسابيع المتوالية التي تعتبر ثباتاً
  static const int stagnationWeeks = 3;

  // ── تعريفات نتائج التقييم ────────────────────────────────
  static const Map<String, EvalConfig> _evals = {
    's1': EvalConfig(
      code: 's1',
      arabicLabel: 'ممتاز جدا جدا',
      englishLabel: 'Outstanding',
      icon: 'emoji_events',
    ),
    's2': EvalConfig(
      code: 's2',
      arabicLabel: 'ممتاز جدا',
      englishLabel: 'Excellent',
      icon: 'star',
    ),
    's3': EvalConfig(
      code: 's3',
      arabicLabel: 'ممتاز',
      englishLabel: 'Great',
      icon: 'thumb_up',
    ),
    'rv': EvalConfig(
      code: 'rv',
      arabicLabel: 'استعادة المستوى',
      englishLabel: 'Level Restored',
      icon: 'trending_up',
    ),
    'gd': EvalConfig(
      code: 'gd',
      arabicLabel: 'جيد',
      englishLabel: 'Good',
      icon: 'check_circle',
    ),
    'st': EvalConfig(
      code: 'st',
      arabicLabel: 'ثبات',
      englishLabel: 'Stagnation',
      icon: 'remove_circle_outline',
    ),
    'ws': EvalConfig(
      code: 'ws',
      arabicLabel: 'تحذير ثبات',
      englishLabel: 'Warning Plateau',
      icon: 'warning',
    ),
    'dn': EvalConfig(
      code: 'dn',
      arabicLabel: 'انخفاض',
      englishLabel: 'Decline',
      icon: 'trending_down',
    ),
    'beg': EvalConfig(
      code: 'beg',
      arabicLabel: 'بداية',
      englishLabel: 'Beginning',
      icon: 'play_circle',
    ),
  };

  // ────────────────────────────────────────────────────────────
  // WORKOUT FUNCTIONS
  // ────────────────────────────────────────────────────────────

  /// حساب 1RM باستخدام معادلة Epley
  ///
  /// [weight] الوزن بالكيلوغرام
  /// [reps] عدد التكرارات
  ///
  /// يُرجع الـ 1RM المقدَّر، أو 0 إذا كانت المدخلات غير صالحة
  static double epley(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return (weight * (1 + reps / 30)).roundToDouble();
  }

  /// حساب الحجم الكلي لمجموعة من السيتات (وزن × تكرارات)
  static double volume(List<SetRecord> sets) {
    return sets.fold(
      0,
      (sum, s) => sum + (s.weight * s.reps),
    );
  }

  /// إيجاد أفضل ست (الأعلى 1RM) من قائمة سيتات
  ///
  /// يُرجع null إذا كانت القائمة فارغة
  static SetRecord? bestSet(List<SetRecord> sets) {
    if (sets.isEmpty) return null;
    return sets.reduce((best, s) {
      final bestE = epley(best.weight, best.reps);
      final currentE = epley(s.weight, s.reps);
      return currentE > bestE ? s : best;
    });
  }

  /// استخراج أفضل أداء من سجل التمارين
  static (SetRecord, DateTime)? getPersonalRecord(
      List<WorkoutSession> history) {
    if (history.isEmpty) return null;

    SetRecord? bestRecord;
    DateTime? bestDate;
    double bestE = 0;

    for (final session in history) {
      for (final ex in session.exercises) {
        final bs = bestSet(ex.sets);
        if (bs == null) continue;
        final e = epley(bs.weight, bs.reps);
        if (e > bestE) {
          bestE = e;
          bestRecord = bs;
          bestDate = session.date;
        }
      }
    }

    if (bestRecord == null || bestDate == null) return null;
    return (bestRecord, bestDate);
  }

  /// حساب الفارق بالأيام بين تاريخين
  static int daysBetween(DateTime a, DateTime b) {
    return (a.difference(b).inMilliseconds.abs() / 86400000).round();
  }

  /// حساب الفارق بالأسابيع بين تاريخين
  static double weeksBetween(DateTime a, DateTime b) {
    return daysBetween(a, b) / 7;
  }

  /// حساب رقم الأسبوع في السنة
  static int _weekNum(DateTime d) {
    final jan1 = DateTime(d.year, 1, 1);
    return ((d.difference(jan1).inDays + jan1.weekday + 1) / 7).ceil();
  }

  /// فحص الثبات لـ 3 أسابيع متتالية
  ///
  /// يُرجع true إذا كانت نفس الوزن ونفس التكرارات لـ 3 أسابيع
  static bool isStagnant3Weeks(List<WorkoutSession> history) {
    if (history.length < 3) return false;

    // ترتيب من الأحدث للأقدم
    final sorted = [...history]
      ..sort((a, b) => b.date.compareTo(a.date));

    final seenWeeks = <String>{};
    final weekEntries = <({DateTime date, double weight, int reps})>[];

    for (final session in sorted) {
      final wk = '${session.date.year}-${_weekNum(session.date)}';
      if (!seenWeeks.contains(wk)) {
        seenWeeks.add(wk);
        // أفضل ست في هذه الجلسة (أول تمرين في السجل)
        if (session.exercises.isNotEmpty) {
          final bs = bestSet(session.exercises.first.sets);
          if (bs != null) {
            weekEntries.add((
              date: session.date,
              weight: bs.weight,
              reps: bs.reps,
            ));
          }
        }
      }
      if (weekEntries.length >= 3) break;
    }

    if (weekEntries.length < 3) return false;

    return weekEntries[0].weight == weekEntries[1].weight &&
        weekEntries[1].weight == weekEntries[2].weight &&
        weekEntries[0].reps == weekEntries[1].reps &&
        weekEntries[1].reps == weekEntries[2].reps;
  }

  /// فحص استعادة المستوى
  ///
  /// يُرجع true إذا كان الأداء الحالي ≥ أفضل أداء تاريخي
  /// مع أن الأداء السابق كان أقل منه
  static bool isRecovery(
      List<WorkoutSession> history, double currW, int currR) {
    if (history.length < 2) return false;

    // أفضل 1RM في كل السجل ما عدا الأخير
    final prevSessions = history.sublist(0, history.length - 1);
    double prevBest = 0;
    for (final session in prevSessions) {
      for (final ex in session.exercises) {
        final bs = bestSet(ex.sets);
        if (bs != null) {
          final e = epley(bs.weight, bs.reps);
          if (e > prevBest) prevBest = e;
        }
      }
    }

    // آخر ست في الجلسة قبل الأخيرة
    double prevLast = 0;
    if (history.length >= 2) {
      final prevSession = history[history.length - 2];
      if (prevSession.exercises.isNotEmpty) {
        final lastSets = prevSession.exercises.first.sets;
        if (lastSets.isNotEmpty) {
          final ls = lastSets.last;
          prevLast = epley(ls.weight, ls.reps);
        }
      }
    }

    final currE = epley(currW, currR);
    return currE >= prevBest && prevLast < prevBest;
  }

  /// الدالة الرئيسية للتقييم
  ///
  /// [prev] الأداء السابق {weight, reps, date}
  /// [curr] الأداء الحالي {weight, reps}
  /// [history] سجل جلسات التمرين كاملاً
  static EvalResult evaluate({
    required _PerformancePoint? prev,
    required _PerformancePoint curr,
    required List<WorkoutSession> history,
  }) {
    if (prev == null) return _buildResult('beg');

    final pW = prev.weight;
    final cW = curr.weight;
    final pR = prev.reps;
    final cR = curr.reps;
    final wD = double.parse((cW - pW).toStringAsFixed(2));
    final rD = cR - pR;

    // فحص استعادة المستوى
    if (isRecovery(history, cW, cR)) return _buildResult('rv');

    // فحص الثبات لـ 3 أسابيع
    if (isStagnant3Weeks(history)) return _buildResult('ws');

    // انخفاض
    if (wD < 0 || (wD == 0 && rD < 0)) return _buildResult('dn');

    // لا تغيير
    if (wD == 0 && rD == 0) return _buildResult('st');

    // نفس الوزن، تكرارات أكثر
    if (wD == 0 && rD > 0) {
      final weeks = prev.date != null
          ? weeksBetween(prev.date!, curr.date ?? DateTime.now())
          : 99.0;

      if (rD >= 2) {
        if (weeks <= 1) return _buildResult('s1');
        if (weeks <= 2) return _buildResult('s2');
        if (weeks <= 3) return _buildResult('s3');
        return _buildResult('gd');
      }

      if (rD == 1) {
        if (weeks <= 1) return _buildResult('s2');
        if (weeks <= 2) return _buildResult('s3');
        if (weeks <= 3) return _buildResult('gd');
        return _buildResult('st');
      }
    }

    // الوزن ارتفع
    if (wD > 0) {
      if (rD >= 0) return _buildResult('s1');

      final rDown = rD.abs();

      if (wD >= 2 && wD <= 3) {
        if (rDown == 1) return _buildResult('s3');
        if (rDown == 2) return _buildResult('gd');
        if (rDown == 3) return _buildResult('st');
        return _buildResult('dn');
      }

      if (wD >= 4 && wD <= 6) {
        if (rDown == 1) return _buildResult('s2');
        if (rDown == 2) return _buildResult('s3');
        if (rDown == 3) return _buildResult('st');
        return _buildResult('dn');
      }

      // أي زيادة أخرى في الوزن
      if (rDown <= 1) return _buildResult('s3');
      if (rDown <= 2) return _buildResult('gd');
      if (rDown <= 3) return _buildResult('st');
      return _buildResult('dn');
    }

    return _buildResult('st');
  }

  /// اقتراح زيادة أو تخفيض الوزن بناءً على عدد التكرارات
  static RepSuggestion? repSuggestion(int reps) {
    if (reps >= upThreshold) {
      return const RepSuggestion(
        type: 'up',
        arabicText: 'ارفع الوزن',
        englishText: 'Increase Weight',
      );
    }
    if (reps <= downThreshold) {
      return const RepSuggestion(
        type: 'down',
        arabicText: 'خفّض الوزن',
        englishText: 'Decrease Weight',
      );
    }
    return null;
  }

  /// فحص Personal Record
  static bool checkPR(
      List<WorkoutSession> history, double currW, int currR) {
    if (history.isEmpty) return false;

    double prevBest = 0;
    for (final session in history) {
      for (final ex in session.exercises) {
        final bs = bestSet(ex.sets);
        if (bs != null) {
          final e = epley(bs.weight, bs.reps);
          if (e > prevBest) prevBest = e;
        }
      }
    }

    return epley(currW, currR) > prevBest;
  }

  // ────────────────────────────────────────────────────────────
  // NUTRITION FUNCTIONS
  // ────────────────────────────────────────────────────────────

  /// حساب معدل الأيض الأساسي (BMR) بمعادلة Mifflin-St Jeor
  ///
  /// [weight] الوزن بالكيلوغرام
  /// [height] الطول بالسنتيمتر
  /// [age] العمر بالسنوات
  /// [gender] الجنس
  static double calcBMR({
    required double weight,
    required double height,
    required int age,
    required Gender gender,
  }) {
    final base = 10 * weight + 6.25 * height - 5 * age;
    return gender == Gender.male
        ? (base + 5).roundToDouble()
        : (base - 161).roundToDouble();
  }

  /// حساب إجمالي احتياج الطاقة (TDEE)
  static double calcTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    return (bmr * activityLevel.factor).roundToDouble();
  }

  /// حساب توزيع الماكرو
  ///
  /// [calories] إجمالي السعرات الحرارية
  /// [goal] الهدف: loseWeight / maintain / gainMuscle
  static MacroResult calcMacros({
    required double calories,
    required String goal,
  }) {
    final ratios = switch (goal) {
      'loseWeight' => (p: 0.35, c: 0.35, f: 0.30),
      'gainMuscle' => (p: 0.25, c: 0.50, f: 0.25),
      _ => (p: 0.30, c: 0.40, f: 0.30), // maintain
    };

    return MacroResult(
      calories: calories,
      protein: (calories * ratios.p / 4).roundToDouble(),
      carbs: (calories * ratios.c / 4).roundToDouble(),
      fat: (calories * ratios.f / 9).roundToDouble(),
      fiber: (calories * 0.014).roundToDouble(),
    );
  }

  /// تعديل عنصر غذائي بناءً على كمية جديدة
  static FoodItem adjustByAmount(FoodItem food, double newAmt) {
    final factor = newAmt / (food.amount > 0 ? food.amount : 100);
    return food.copyWith(
      amount: newAmt,
      calories: (food.calories * factor).roundToDouble(),
      protein: double.parse((food.protein * factor).toStringAsFixed(1)),
      carbs: double.parse((food.carbs * factor).toStringAsFixed(1)),
      fat: double.parse((food.fat * factor).toStringAsFixed(1)),
      fiber: double.parse((food.fiber * factor).toStringAsFixed(1)),
    );
  }

  /// تعديل عنصر غذائي بناءً على سعرات مستهدفة
  static FoodItem adjustByCalories(FoodItem food, double targetCal) {
    final factor = targetCal / (food.calories > 0 ? food.calories : 1);
    return adjustByAmount(food, (food.amount * factor).roundToDouble());
  }

  /// اقتراح وجبة بناءً على السعرات المتبقية
  ///
  /// [remaining] السعرات المتبقية
  /// [pref] التفضيل: cheapest / bestProtein / lightest / cleanest / balanced
  /// [foodDb] قاعدة الأطعمة
  static List<FoodItem> suggestMeal({
    required double remaining,
    required String pref,
    required List<FoodItem> foodDb,
  }) {
    if (foodDb.isEmpty) return [];

    var scored = foodDb
        .where(
          (f) =>
              f.calories > 0 &&
              f.calories <= remaining * 1.25 &&
              f.calories >= remaining * 0.3,
        )
        .map((f) {
          final newAmt = (remaining / (f.calories / f.amount)).roundToDouble();
          return adjustByAmount(f, newAmt);
        })
        .toList();

    scored.sort((a, b) {
      return switch (pref) {
        'cheapest' => a.cost.compareTo(b.cost),
        'bestProtein' => b.protein.compareTo(a.protein),
        'lightest' => a.calories.compareTo(b.calories),
        'cleanest' => a.fat.compareTo(b.fat),
        _ => (a.calories - remaining).abs().compareTo(
              (b.calories - remaining).abs(),
            ),
      };
    });

    return scored.take(6).toList();
  }

  /// تحليل نص وجبة وتحويله لعناصر غذائية
  ///
  /// يدعم: وحدات عربية، Fuzzy matching، تطبيع النص العربي
  static MealParseResult parseMealText(String text, List<FoodItem> foodDb) {
    if (text.isEmpty || foodDb.isEmpty) {
      return const MealParseResult(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        items: [],
        unmatched: [],
      );
    }

    final lines = text.split('\n').where((l) => l.isNotEmpty).toList();
    final items = <FoodItem>[];
    final unmatched = <String>[];
    double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0,
        totalFib = 0;

    for (final line in lines) {
      double amt = 100;
      String q = line;

      // استخراج الكمية والوحدة
      final amtMatch = _amtRegex.firstMatch(line);
      if (amtMatch != null) {
        final num = double.tryParse(amtMatch.group(1) ?? '0') ?? 0;
        final unit = amtMatch.group(2)?.trim() ?? '';
        final unitGrams = _unitToGrams[unit];
        amt = unitGrams != null ? num * unitGrams : num;
        q = line.replaceFirst(amtMatch.group(0)!, '');
      } else {
        // رقم مجرد في البداية → جرام
        final numStart = _numStartRegex.firstMatch(line);
        if (numStart != null) {
          amt = double.tryParse(numStart.group(1) ?? '100') ?? 100;
          q = line.replaceFirst(numStart.group(0)!, '');
        }
      }

      // تنظيف النص من الأرقام والحروف الزائدة
      q = q
          .replaceAll(RegExp(r'[\d.,،\-_()\[\]]+'), ' ')
          .replaceAll(
            RegExp(r'\b(من|مع|على|في|و|أو|بدون|بدُون)\b'),
            ' ',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (q.isEmpty) continue;

      final food = _findFood(q, foodDb);
      if (food != null) {
        final adjusted = adjustByAmount(food, amt);
        totalCal += adjusted.calories;
        totalPro += adjusted.protein;
        totalCarb += adjusted.carbs;
        totalFat += adjusted.fat;
        totalFib += adjusted.fiber;
        items.add(adjusted);
      } else {
        unmatched.add(q);
      }
    }

    return MealParseResult(
      calories: totalCal,
      protein: totalPro,
      carbs: totalCarb,
      fat: totalFat,
      fiber: totalFib,
      items: items,
      unmatched: unmatched,
    );
  }

  // ────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ────────────────────────────────────────────────────────────

  static EvalResult _buildResult(String code) {
    final config = _evals[code]!;
    return EvalResult(
      code: config.code,
      arabicLabel: config.arabicLabel,
      englishLabel: config.englishLabel,
      icon: config.icon,
    );
  }

  /// تطبيع النص العربي لمطابقة أفضل
  static String _normalizeAr(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp('[أإآاى]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '') // تشكيل
        .replaceAll(RegExp(r'ال(?=\S)'), '') // أل التعريف
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// حساب Levenshtein distance بين نصّين
  static int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final row = List<int>.generate(b.length + 1, (i) => i);

    for (var i = 1; i <= a.length; i++) {
      var prev = i;
      for (var j = 1; j <= b.length; j++) {
        final val = a[i - 1] == b[j - 1]
            ? row[j - 1]
            : 1 + [row[j - 1], row[j], prev].reduce(min);
        row[j - 1] = prev;
        prev = val;
      }
      row[b.length] = prev;
    }

    return row[b.length];
  }

  /// حساب التشابه (0-1) بين نصّين
  static double _similarity(String query, String name) {
    final nq = _normalizeAr(query);
    final nn = _normalizeAr(name);

    if (nq.isEmpty || nn.isEmpty) return 0;
    if (nq == nn) return 1;
    if (nn.contains(nq) || nq.contains(nn)) return 0.92;

    // مطابقة كلمة واحدة
    final qWords = nq.split(' ').where((w) => w.length > 1).toList();
    final nWords = nn.split(' ').where((w) => w.length > 1).toList();

    final wordHit = qWords.any(
      (qw) => nWords.any(
        (nw) => nw.contains(qw) || qw.contains(nw) || _levenshtein(qw, nw) <= 1,
      ),
    );

    if (wordHit) return 0.82;

    final dist = _levenshtein(nq, nn);
    final maxL = max(nq.length, nn.length);
    return maxL > 0 ? max(0, 1 - dist / maxL).toDouble() : 0;
  }

  /// البحث عن أقرب طعام في قاعدة البيانات
  static FoodItem? _findFood(String query, List<FoodItem> foodDb) {
    if (query.isEmpty) return null;

    FoodItem? best;
    double bestScore = 0.58; // الحد الأدنى للمطابقة

    for (final food in foodDb) {
      double s = _similarity(query, food.name);
      if (s > bestScore) {
        bestScore = s;
        best = food;
      }

      for (final alias in food.aliases) {
        s = _similarity(query, alias);
        if (s > bestScore) {
          bestScore = s;
          best = food;
        }
      }
    }

    return best;
  }

  // ── الوحدات → جرام ──────────────────────────────────────
  static const Map<String, double> _unitToGrams = {
    'كوب': 240,
    'كأس': 240,
    'كوب كبير': 300,
    'كوب صغير': 180,
    'ملعقة كبيرة': 15,
    'ملعقة صغيرة': 5,
    'ملعقه كبيره': 15,
    'ملعقه صغيره': 5,
    'ملعقة': 12,
    'ملعقه': 12,
    'قطعة': 100,
    'قطعه': 100,
    'حبة': 100,
    'حبه': 100,
    'شريحة': 30,
    'شريحه': 30,
    'وحدة': 100,
    'وحده': 100,
    'حصة': 100,
    'حصه': 100,
    'كيلو': 1000,
    'kg': 1000,
    'g': 1,
    'جم': 1,
    'جرام': 1,
    'غ': 1,
    'gram': 1,
    'gm': 1,
  };

  static final RegExp _amtRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*(جرام|جم|g|غ|gram|gm|كوب|كأس|ملعقة كبيرة|ملعقة صغيرة|ملعقه كبيره|ملعقه صغيره|ملعقة|ملعقه|قطعة|قطعه|حبة|حبه|شريحة|شريحه|وحدة|وحده|حصة|حصه|كيلو|kg)',
    caseSensitive: false,
  );

  static final RegExp _numStartRegex = RegExp(r'^\s*(\d+(?:\.\d+)?)\s+');
}

// ── Helper Classes ────────────────────────────────────────────

/// نقطة أداء واحدة (وزن + تكرارات + تاريخ)
class _PerformancePoint {
  const _PerformancePoint({
    required this.weight,
    required this.reps,
    this.date,
  });

  final double weight;
  final int reps;
  final DateTime? date;
}

/// إعداد نتيجة التقييم
class EvalConfig {
  const EvalConfig({
    required this.code,
    required this.arabicLabel,
    required this.englishLabel,
    required this.icon,
  });

  final String code;
  final String arabicLabel;
  final String englishLabel;
  final String icon;
}

/// بناء نقطة أداء من SetRecord
extension SetRecordExt on SetRecord {
  _PerformancePoint toPerformancePoint({DateTime? date}) {
    return _PerformancePoint(
      weight: weight,
      reps: reps,
      date: date,
    );
  }
}

/// تقييم الأداء من سجل جلسة تمرين
extension WorkoutSessionEval on WorkoutSession {
  /// تقييم تمرين محدد مقارنةً بالتاريخ
  EvalResult? evaluateExercise({
    required String exerciseName,
    required List<WorkoutSession> history,
  }) {
    final currentEx = exercises.where((e) => e.exerciseName == exerciseName);
    if (currentEx.isEmpty) return null;

    final currBest = Evaluator.bestSet(currentEx.first.sets);
    if (currBest == null) return null;

    // الجلسة السابقة للتمرين نفسه
    WorkoutSession? prevSession;
    for (final session in history.reversed) {
      if (session.id == id) continue;
      final hasEx = session.exercises.any((e) => e.exerciseName == exerciseName);
      if (hasEx) {
        prevSession = session;
        break;
      }
    }

    _PerformancePoint? prev;
    if (prevSession != null) {
      final prevEx = prevSession.exercises
          .where((e) => e.exerciseName == exerciseName)
          .firstOrNull;
      if (prevEx != null) {
        final prevBest = Evaluator.bestSet(prevEx.sets);
        if (prevBest != null) {
          prev = prevBest.toPerformancePoint(date: prevSession.date);
        }
      }
    }

    return Evaluator.evaluate(
      prev: prev,
      curr: currBest.toPerformancePoint(date: date),
      history: history,
    );
  }
}
