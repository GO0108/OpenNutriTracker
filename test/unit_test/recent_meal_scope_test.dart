import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';

IntakeEntity _intake(String name, IntakeTypeEntity type, double amount) =>
    IntakeEntity(
      id: name,
      unit: 'g',
      amount: amount,
      type: type,
      meal: MealEntity(
        code: name,
        name: name,
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: MealNutrimentsEntity.empty(),
        source: MealSourceEntity.custom,
      ),
      dateTime: DateTime(2026, 11, 20),
    );

class _ByType extends Fake implements GetIntakeUsecase {
  final asked = <IntakeTypeEntity?>[];

  @override
  Future<List<IntakeEntity>> getRecentIntake({IntakeTypeEntity? type}) async {
    asked.add(type);
    final all = [
      _intake('pão', IntakeTypeEntity.breakfast, 50),
      _intake('feijão', IntakeTypeEntity.lunch, 140),
    ];
    return type == null ? all : all.where((i) => i.type == type).toList();
  }
}

class _Config extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

void main() {
  test('a scoped list shows only that meal, with the amounts', () async {
    final intakes = _ByType();
    final bloc = RecentMealBloc(intakes, _Config())
      ..scopeTo(IntakeTypeEntity.lunch);
    bloc.add(const LoadRecentMealEvent(searchString: ''));
    final state = await bloc.stream.firstWhere(
      (s) => s is RecentMealLoadedState,
    ) as RecentMealLoadedState;
    expect(intakes.asked, [IntakeTypeEntity.lunch]);
    expect(state.recentMeals.single.name, 'feijão');
    expect(state.recentIntakes.single.amount, 140);
    await bloc.close();
  });

  test('unscoped keeps the old all-meals history', () async {
    final intakes = _ByType();
    final bloc = RecentMealBloc(intakes, _Config());
    bloc.add(const LoadRecentMealEvent(searchString: ''));
    final state = await bloc.stream.firstWhere(
      (s) => s is RecentMealLoadedState,
    ) as RecentMealLoadedState;
    expect(intakes.asked, [null]);
    expect(state.recentMeals, hasLength(2));
    await bloc.close();
  });
}
