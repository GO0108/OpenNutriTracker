import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/goal_suggestion_calc.dart';

void main() {
  test('0.7 kg/week from 2700 kcal maintenance', () {
    final s = GoalSuggestionCalc.suggest(
      tdeeKcal: 2700,
      kgPerWeek: -0.7,
      weightKg: 90,
      floorKcal: 1500,
    );
    expect(s.dietOnlyKcal, closeTo(1930, 0.01));
    expect(s.extraBurnKcal, 0);
    expect(s.walkKcal, closeTo(290.25, 0.01));
    expect(s.withWalkKcal, closeTo(2220.25, 0.01));
  });

  test('a rate below the floor asks for exercise instead', () {
    final s = GoalSuggestionCalc.suggest(
      tdeeKcal: 2000,
      kgPerWeek: -1.0,
      weightKg: 70,
      floorKcal: 1500,
    );
    expect(s.dietOnlyKcal, 1500);
    expect(s.extraBurnKcal, closeTo(600, 0.01));
    expect(s.withWalkKcal, 1500);
  });
}
