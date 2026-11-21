import 'package:equatable/equatable.dart';

/// What a weekly rate means for a day: how much to eat, and what a daily
/// walk buys.
class GoalSuggestion extends Equatable {
  /// Energy to eat with no planned exercise, never below the safe floor.
  final double dietOnlyKcal;

  /// Exercise still needed each day when eating at the floor is not enough
  /// for the rate; zero when diet alone gets there.
  final double extraBurnKcal;

  /// The daily walk the suggestion is built around.
  final int walkMinutes;
  final double walkKcal;

  /// Energy to eat on a day with that walk, never below the safe floor.
  final double withWalkKcal;

  const GoalSuggestion({
    required this.dietOnlyKcal,
    required this.extraBurnKcal,
    required this.walkMinutes,
    required this.walkKcal,
    required this.withWalkKcal,
  });

  @override
  List<Object?> get props => [
    dietOnlyKcal,
    extraBurnKcal,
    walkMinutes,
    walkKcal,
    withWalkKcal,
  ];
}

class GoalSuggestionCalc {
  /// The app's own conversion: 1 kg a week is 1100 kcal a day.
  static const kcalPerKgPerWeekDaily = 1100.0;

  /// Brisk walking (about 5.6 km/h), Compendium of Physical Activities.
  static const walkMet = 4.3;
  static const walkMinutes = 45;

  /// [tdeeKcal]: maintenance energy without logged exercise. [kgPerWeek]:
  /// the signed weekly rate (negative to lose). [floorKcal]: the lowest
  /// daily intake the app recommends.
  static GoalSuggestion suggest({
    required double tdeeKcal,
    required double kgPerWeek,
    required double weightKg,
    required double floorKcal,
  }) {
    final target = tdeeKcal + kgPerWeek * kcalPerKgPerWeekDaily;
    final dietOnly = target < floorKcal ? floorKcal : target;
    final extraBurn = target < floorKcal ? floorKcal - target : 0.0;
    final walkKcal = walkMet * weightKg * walkMinutes / 60;
    final withWalkTarget = target + walkKcal;
    return GoalSuggestion(
      dietOnlyKcal: dietOnly,
      extraBurnKcal: extraBurn,
      walkMinutes: walkMinutes,
      walkKcal: walkKcal,
      withWalkKcal: withWalkTarget < floorKcal ? floorKcal : withWalkTarget,
    );
  }
}
