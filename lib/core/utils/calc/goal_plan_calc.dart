import 'package:equatable/equatable.dart';

/// The weekly rate that reaches a target weight by a target date.
class GoalPlan extends Equatable {
  /// Signed kg per week: negative to lose, positive to gain.
  final double kgPerWeek;

  /// True when the date asked for more than [GoalPlanCalc.maxKgPerWeek],
  /// so [kgPerWeek] was held at that limit instead.
  final bool capped;

  /// When [capped], the earliest date the target is reachable at the limit.
  final DateTime? earliestSafeDate;

  const GoalPlan({
    required this.kgPerWeek,
    required this.capped,
    this.earliestSafeDate,
  });

  @override
  List<Object?> get props => [kgPerWeek, capped, earliestSafeDate];
}

class GoalPlanCalc {
  /// The fastest rate the app will plan for — the same bound the weekly
  /// goal dialog offers. Faster loss costs lean mass and is hard to keep.
  static const maxKgPerWeek = 1.0;

  /// Null when there is nothing to plan: the date is today or past, or the
  /// target is the current weight.
  static GoalPlan? plan({
    required double currentKg,
    required double targetKg,
    required DateTime today,
    required DateTime targetDate,
  }) {
    final start = DateTime.utc(today.year, today.month, today.day);
    final end = DateTime.utc(targetDate.year, targetDate.month, targetDate.day);
    final days = end.difference(start).inDays;
    final delta = targetKg - currentKg;
    if (days <= 0 || delta == 0) return null;

    final needed = delta / (days / 7);
    if (needed.abs() <= maxKgPerWeek) {
      return GoalPlan(kgPerWeek: needed, capped: false);
    }
    final safeDays = (delta.abs() / maxKgPerWeek * 7).ceil();
    final earliest = start.add(Duration(days: safeDays));
    return GoalPlan(
      kgPerWeek: maxKgPerWeek * delta.sign,
      capped: true,
      earliestSafeDate: DateTime(earliest.year, earliest.month, earliest.day),
    );
  }
}
