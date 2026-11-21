import 'package:equatable/equatable.dart';

enum AdequacyStatus { noData, low, ok, high }

/// How a day's intake compares with the energy goal and with healthy
/// ranges for where that energy comes from.
class NutritionAdequacy extends Equatable {
  final AdequacyStatus kcal;
  final AdequacyStatus carbs;
  final AdequacyStatus fat;
  final AdequacyStatus protein;
  final AdequacyStatus proteinPerKg;

  /// Shares (0–1) of the energy from carbohydrate, fat and protein.
  final double carbsPct;
  final double fatPct;
  final double proteinPct;

  final double proteinGPerKg;

  const NutritionAdequacy({
    required this.kcal,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.proteinPerKg,
    required this.carbsPct,
    required this.fatPct,
    required this.proteinPct,
    required this.proteinGPerKg,
  });

  bool get hasData => kcal != AdequacyStatus.noData;

  @override
  List<Object?> get props => [
    kcal,
    carbs,
    fat,
    protein,
    proteinPerKg,
    carbsPct,
    fatPct,
    proteinPct,
    proteinGPerKg,
  ];
}

class NutritionAdequacyCalc {
  /// Acceptable Macronutrient Distribution Ranges for adults (Institute of
  /// Medicine): share of energy from each macronutrient.
  static const carbsRange = (min: 0.45, max: 0.65);
  static const fatRange = (min: 0.20, max: 0.35);
  static const proteinRange = (min: 0.10, max: 0.35);

  /// Protein floor while eating in a deficit, per kg of body weight — a
  /// common reference for keeping lean mass; adjust with a professional.
  static const minProteinGPerKg = 1.6;

  /// How far from the energy goal still counts as on target.
  static const kcalTolerance = 0.10;

  static NutritionAdequacy evaluate({
    required double kcalIntake,
    required double kcalGoal,
    required double carbsG,
    required double fatG,
    required double proteinG,
    required double weightKg,
  }) {
    final macroKcal = 4 * carbsG + 9 * fatG + 4 * proteinG;
    final hasMacros = macroKcal > 0;
    double share(double kcal) => hasMacros ? kcal / macroKcal : 0;
    final carbsPct = share(4 * carbsG);
    final fatPct = share(9 * fatG);
    final proteinPct = share(4 * proteinG);

    AdequacyStatus inRange(double value, ({double min, double max}) range) {
      if (!hasMacros) return AdequacyStatus.noData;
      if (value < range.min) return AdequacyStatus.low;
      if (value > range.max) return AdequacyStatus.high;
      return AdequacyStatus.ok;
    }

    final AdequacyStatus kcal;
    if (kcalGoal <= 0 || kcalIntake <= 0) {
      kcal = AdequacyStatus.noData;
    } else if (kcalIntake < (1 - kcalTolerance) * kcalGoal) {
      kcal = AdequacyStatus.low;
    } else if (kcalIntake > (1 + kcalTolerance) * kcalGoal) {
      kcal = AdequacyStatus.high;
    } else {
      kcal = AdequacyStatus.ok;
    }

    final hasWeight = weightKg > 0 && proteinG > 0;
    final proteinGPerKg = weightKg > 0 ? proteinG / weightKg : 0.0;

    return NutritionAdequacy(
      kcal: kcal,
      carbs: inRange(carbsPct, carbsRange),
      fat: inRange(fatPct, fatRange),
      protein: inRange(proteinPct, proteinRange),
      proteinPerKg: !hasWeight
          ? AdequacyStatus.noData
          : proteinGPerKg < minProteinGPerKg
          ? AdequacyStatus.low
          : AdequacyStatus.ok,
      carbsPct: carbsPct,
      fatPct: fatPct,
      proteinPct: proteinPct,
      proteinGPerKg: proteinGPerKg,
    );
  }
}
