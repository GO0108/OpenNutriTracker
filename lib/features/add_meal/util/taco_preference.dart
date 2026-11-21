import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// [ranked] with [tacoHits] moved up to sit right after the user's own
/// custom meals and recipes, in the order the TACO search gave them.
///
/// For a Portuguese meal description the bundled TACO record is the best
/// answer the app has — analysed Brazilian food, cooked as eaten — while
/// the other pools tend to offer a branded dry-bean package for "feijão"
/// (four times the energy of cooked beans) or an English survey record.
/// The user's own content still comes first, as everywhere else in the
/// resolver.
///
/// A hit missing from [ranked] (its source search failed or was skipped)
/// is inserted anyway: the table is local and cannot have been down.
List<MealEntity> preferTaco(
  List<MealEntity> ranked,
  List<MealEntity> tacoHits,
) {
  if (tacoHits.isEmpty) return ranked;
  final tacoCodes = {for (final meal in tacoHits) meal.code};
  bool isOwn(MealEntity meal) =>
      meal.source == MealSourceEntity.custom ||
      meal.source == MealSourceEntity.recipe;
  return [
    ...ranked.where(isOwn),
    ...tacoHits,
    ...ranked.where((m) => !isOwn(m) && !tacoCodes.contains(m.code)),
  ];
}
