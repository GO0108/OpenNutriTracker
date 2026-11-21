import 'package:equatable/equatable.dart';

/// `MealEntity.backendSource` of a food from the bundled TACO table, and its
/// key in `SPConst.foodSourceDisplayNames`.
const tacoSourceCode = 'taco';

/// One household measure for a TACO food: "1 concha" weighing 140 g.
///
/// [en] is the English key the AI's `portion` field is matched against
/// (`matchPortionToKey`), so a model that answers "ladle" for "uma concha"
/// lands on this row.
class TacoPortion extends Equatable {
  final String label;
  final String en;
  final double grams;

  const TacoPortion({
    required this.label,
    required this.en,
    required this.grams,
  });

  factory TacoPortion.fromJson(Map<String, Object?> json) => TacoPortion(
    label: json['label']! as String,
    en: json['en']! as String,
    grams: (json['g']! as num).toDouble(),
  );

  @override
  List<Object?> get props => [label, en, grams];
}

/// A food from the Tabela Brasileira de Composição de Alimentos (TACO, 4th
/// edition, NEPA–UNICAMP 2011), as bundled in `assets/taco/taco.json` by
/// `tool/taco/convert_taco.dart`.
///
/// Every nutrient is per 100 g of edible part, in the units the app already
/// uses for `MealNutrimentsEntity` (g, mg, µg RAE). Null means TACO did not
/// measure it, not zero.
class TacoFood extends Equatable {
  /// TACO category of drinks ("Bebidas (alcoólicas e não alcoólicas)").
  static const beverageCategoryId = 8;

  final int id;
  final String name;
  final int categoryId;
  final double? kcal;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? fiber;
  final double? saturatedFat;
  final double? cholesterol;
  final double? sodium;
  final double? potassium;
  final double? magnesium;
  final double? calcium;
  final double? iron;
  final double? zinc;
  final double? phosphorus;
  final double? vitaminA;
  final double? vitaminC;
  final double? vitaminB6;
  final double? niacin;
  final List<String> aliases;
  final List<TacoPortion> portions;

  const TacoFood({
    required this.id,
    required this.name,
    required this.categoryId,
    this.kcal,
    this.protein,
    this.fat,
    this.carbs,
    this.fiber,
    this.saturatedFat,
    this.cholesterol,
    this.sodium,
    this.potassium,
    this.magnesium,
    this.calcium,
    this.iron,
    this.zinc,
    this.phosphorus,
    this.vitaminA,
    this.vitaminC,
    this.vitaminB6,
    this.niacin,
    this.aliases = const [],
    this.portions = const [],
  });

  factory TacoFood.fromJson(Map<String, Object?> json) {
    double? n(String key) => (json[key] as num?)?.toDouble();
    return TacoFood(
      id: (json['id']! as num).toInt(),
      name: json['name']! as String,
      categoryId: (json['categoryId']! as num).toInt(),
      kcal: n('kcal'),
      protein: n('protein'),
      fat: n('fat'),
      carbs: n('carbs'),
      fiber: n('fiber'),
      saturatedFat: n('saturatedFat'),
      cholesterol: n('cholesterol'),
      sodium: n('sodium'),
      potassium: n('potassium'),
      magnesium: n('magnesium'),
      calcium: n('calcium'),
      iron: n('iron'),
      zinc: n('zinc'),
      phosphorus: n('phosphorus'),
      vitaminA: n('vitaminA'),
      vitaminC: n('vitaminC'),
      vitaminB6: n('vitaminB6'),
      niacin: n('niacin'),
      aliases: [
        for (final alias in (json['aliases'] as List?) ?? const [])
          alias as String,
      ],
      portions: [
        for (final portion in (json['portions'] as List?) ?? const [])
          TacoPortion.fromJson((portion as Map).cast<String, Object?>()),
      ],
    );
  }

  bool get isBeverage => categoryId == beverageCategoryId;

  /// The meal code a TACO food is stored under: unique across sources and
  /// never parseable as an int, so nothing mistakes it for a backend id.
  String get code => 'taco:$id';

  @override
  List<Object?> get props => [id];
}
