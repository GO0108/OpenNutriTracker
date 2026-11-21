import 'package:opennutritracker/features/add_meal/data/data_sources/taco_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/taco_food.dart';

/// A TACO food for tests: every macro 1 g/100 g unless [kcal] says
/// otherwise, which is all the search and resolver tests read.
TacoFood food(
  int id,
  String name,
  int categoryId, {
  List<String> aliases = const [],
  List<Map<String, Object?>> portions = const [],
  double kcal = 100,
}) => TacoFood.fromJson({
  'id': id,
  'name': name,
  'categoryId': categoryId,
  'kcal': kcal,
  'protein': 1.0,
  'fat': 1.0,
  'carbs': 1.0,
  'aliases': aliases,
  'portions': portions,
});

TacoFoodDataSource tacoSource(List<TacoFood> foods) =>
    TacoFoodDataSource(foods);
