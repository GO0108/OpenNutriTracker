import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/goal_plan_calc.dart';

/// Keeps the weekly rate on course for the target date: from today's weight
/// to the target weight in the days that are left.
///
/// Run when the date or target changes and whenever a new weight arrives,
/// so a slow week asks a little more of the next ones and a fast one a
/// little less — always within [GoalPlanCalc.maxKgPerWeek].
class ApplyTargetDateUsecase {
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  final UserRepository _userRepository;

  ApplyTargetDateUsecase(this._userRepository);

  /// The plan now in force, or null when no target date applies (none set,
  /// no target weight, the date has passed, or the target is reached).
  Future<GoalPlan?> apply() async {
    final user = await _userRepository.getUserData();
    final targetDate = user.targetDate;
    final targetKg = user.targetWeightKg;
    if (targetDate == null || targetKg == null) return null;
    final plan = GoalPlanCalc.plan(
      currentKg: user.weightKG,
      targetKg: targetKg,
      today: clock(),
      targetDate: targetDate,
    );
    if (plan == null) return null;
    user.weeklyWeightGoalKg = plan.kgPerWeek;
    user.goal = plan.kgPerWeek < 0
        ? UserWeightGoalEntity.loseWeight
        : UserWeightGoalEntity.gainWeight;
    await _userRepository.updateUserData(user);
    return plan;
  }
}
