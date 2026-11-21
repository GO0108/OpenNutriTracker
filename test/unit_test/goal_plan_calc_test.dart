import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/apply_target_date_usecase.dart';
import 'package:opennutritracker/core/utils/calc/goal_plan_calc.dart';

class _FakeUserRepo extends Fake implements UserRepository {
  UserEntity user;
  UserEntity? saved;

  _FakeUserRepo(this.user);

  @override
  Future<UserEntity> getUserData() async => user;

  @override
  Future<void> updateUserData(UserEntity userEntity) async =>
      saved = userEntity;
}

UserEntity _user({double weight = 90, double? target, DateTime? date}) =>
    UserEntity(
      birthday: DateTime(2000, 1, 1),
      heightCM: 178,
      weightKG: weight,
      gender: UserGenderEntity.male,
      goal: UserWeightGoalEntity.maintainWeight,
      pal: UserPALEntity.lowActive,
      targetWeightKg: target,
      targetDate: date,
    );

void main() {
  final today = DateTime(2026, 11, 21);

  group('GoalPlanCalc', () {
    test('10 kg by 2027-02-28 is about -0.71 kg/week, not capped', () {
      final p = GoalPlanCalc.plan(
        currentKg: 90,
        targetKg: 80,
        today: today,
        targetDate: DateTime(2027, 2, 28),
      )!;
      expect(p.kgPerWeek, closeTo(-0.7071, 0.001));
      expect(p.capped, isFalse);
      expect(p.earliestSafeDate, isNull);
    });

    test('10 kg in a month is capped at 1 kg/week with a safe date', () {
      final p = GoalPlanCalc.plan(
        currentKg: 90,
        targetKg: 80,
        today: today,
        targetDate: DateTime(2026, 12, 21),
      )!;
      expect(p.kgPerWeek, -1.0);
      expect(p.capped, isTrue);
      expect(p.earliestSafeDate, DateTime(2027, 1, 30));
    });

    test('target date today or in the past gives no plan', () {
      expect(
        GoalPlanCalc.plan(
          currentKg: 90,
          targetKg: 80,
          today: today,
          targetDate: today,
        ),
        isNull,
      );
      expect(
        GoalPlanCalc.plan(
          currentKg: 90,
          targetKg: 80,
          today: today,
          targetDate: DateTime(2026, 1, 1),
        ),
        isNull,
      );
    });

    test('already at target gives no plan', () {
      expect(
        GoalPlanCalc.plan(
          currentKg: 80,
          targetKg: 80,
          today: today,
          targetDate: DateTime(2027, 2, 28),
        ),
        isNull,
      );
    });

    test('exactly 1 kg/week is allowed uncapped', () {
      final p = GoalPlanCalc.plan(
        currentKg: 60,
        targetKg: 62,
        today: today,
        targetDate: today.add(const Duration(days: 14)),
      )!;
      expect(p.kgPerWeek, 1.0);
      expect(p.capped, isFalse);
    });
  });

  group('ApplyTargetDateUsecase', () {
    setUp(() => ApplyTargetDateUsecase.clock = () => DateTime(2026, 11, 21, 9));
    tearDown(() => ApplyTargetDateUsecase.clock = DateTime.now);

    test('writes the weekly rate and the lose-weight goal', () async {
      final repo = _FakeUserRepo(
        _user(target: 80, date: DateTime(2027, 2, 28)),
      );
      final plan = await ApplyTargetDateUsecase(repo).apply();
      expect(plan!.capped, isFalse);
      expect(repo.saved!.weeklyWeightGoalKg, closeTo(-0.7071, 0.001));
      expect(repo.saved!.goal, UserWeightGoalEntity.loseWeight);
    });

    test('does nothing without a target date', () async {
      final repo = _FakeUserRepo(_user(target: 80));
      expect(await ApplyTargetDateUsecase(repo).apply(), isNull);
      expect(repo.saved, isNull);
    });
  });
}
