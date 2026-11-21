import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_adequacy_calc.dart';

void main() {
  test('balanced day with low protein per kg', () {
    final a = NutritionAdequacyCalc.evaluate(
      kcalIntake: 2110,
      kcalGoal: 2100,
      carbsG: 250,
      fatG: 70,
      proteinG: 120,
      weightKg: 90,
    );
    expect(a.carbsPct, closeTo(0.474, 0.001));
    expect(a.fatPct, closeTo(0.299, 0.001));
    expect(a.proteinPct, closeTo(0.227, 0.001));
    expect([a.kcal, a.carbs, a.fat, a.protein],
        everyElement(AdequacyStatus.ok));
    expect(a.proteinGPerKg, closeTo(1.333, 0.001));
    expect(a.proteinPerKg, AdequacyStatus.low);
  });

  test('empty day is noData everywhere, no NaN', () {
    final a = NutritionAdequacyCalc.evaluate(
      kcalIntake: 0,
      kcalGoal: 2100,
      carbsG: 0,
      fatG: 0,
      proteinG: 0,
      weightKg: 90,
    );
    expect(
      [a.kcal, a.carbs, a.fat, a.protein, a.proteinPerKg],
      everyElement(AdequacyStatus.noData),
    );
    expect(
      [a.carbsPct, a.fatPct, a.proteinPct, a.proteinGPerKg].any(
        (v) => v.isNaN,
      ),
      isFalse,
    );
    expect(a.hasData, isFalse);
  });

  test('kcal outside ±10% is high or low', () {
    AdequacyStatus k(double intake) => NutritionAdequacyCalc.evaluate(
      kcalIntake: intake,
      kcalGoal: 2000,
      carbsG: 1,
      fatG: 1,
      proteinG: 1,
      weightKg: 90,
    ).kcal;
    expect(k(2500), AdequacyStatus.high);
    expect(k(1700), AdequacyStatus.low);
    expect(k(2150), AdequacyStatus.ok);
  });

  test('fat-heavy day', () {
    final a = NutritionAdequacyCalc.evaluate(
      kcalIntake: 1700,
      kcalGoal: 1700,
      carbsG: 100,
      fatG: 100,
      proteinG: 100,
      weightKg: 0,
    );
    expect(a.fat, AdequacyStatus.high);
    expect(a.carbs, AdequacyStatus.low);
    expect(a.proteinPerKg, AdequacyStatus.noData);
  });
}
