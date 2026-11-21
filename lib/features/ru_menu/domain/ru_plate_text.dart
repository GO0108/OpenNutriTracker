import 'package:opennutritracker/features/ru_menu/data/ru_menu_parser.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';

/// How much of each part of an RU tray to log by default. Estimates of a
/// typical serving, meant to be corrected on the review screen — the tray
/// is self-served and nobody weighs it.
class RuPlateDefaults {
  final int mainG;
  final int riceG;
  final int beansG;
  final int sideG;
  final int saladG;
  final int dessertG;
  final int drinkMl;
  final int breadG;
  final bool includeBread;

  const RuPlateDefaults({
    this.mainG = 120,
    this.riceG = 150,
    this.beansG = 140,
    this.sideG = 100,
    this.saladG = 40,
    this.dessertG = 40,
    this.drinkMl = 250,
    this.breadG = 50,
    this.includeBread = true,
  });
}

/// The tray as the lines the add-food review screen reads — one food per
/// line with an amount, lower case: "150 g arroz", "1 laranja".
///
/// Amounts are written out so the result does not depend on a model: the
/// offline parser reads these lines as well as Claude does, and every food
/// is then matched against TACO first.
String ruMealToLogText(
  RuMeal meal, {
  RuPlateDefaults defaults = const RuPlateDefaults(),
  String restaurant = 'RU',
}) {
  final lines = <String>[];
  final main = meal.mainDish;
  if (main != null) {
    lines.add('${defaults.mainG} g ${_lower(pickRestaurantVariant(main, restaurant: restaurant))}');
  }
  for (final raw in meal.items) {
    final item = pickRestaurantVariant(raw, restaurant: restaurant).toUpperCase();
    final base = _riceAndBeans.firstMatch(item);
    if (base != null) {
      final rice = base.group(1) != null ? 'arroz integral' : 'arroz';
      lines
        ..add('${defaults.riceG} g $rice')
        ..add('${defaults.beansG} g feijão');
      continue;
    }
    final name = _lower(item);
    if (item.startsWith('SALADA')) {
      lines.add('${defaults.saladG} g $name');
    } else if (item.startsWith('REFRESCO') || item.startsWith('SUCO')) {
      lines.add('${defaults.drinkMl} ml $name');
    } else if (_fruits.contains(item)) {
      lines.add('1 $name');
    } else if (_dessertPrefixes.any(item.startsWith)) {
      lines.add('${defaults.dessertG} g $name');
    } else {
      lines.add('${defaults.sideG} g $name');
    }
  }
  if (defaults.includeBread) lines.add('${defaults.breadG} g pão francês');
  return lines.join('\n');
}

/// Lower case, without the commas and semicolons the review screen splits
/// items on — "torta de mandioquinha com cenoura, pts e aveia" is one dish.
String _lower(String text) =>
    text.replaceAll(_separators, ' ').replaceAll(_spaces, ' ').trim().toLowerCase();

final _separators = RegExp(r'[,;+]');
final _spaces = RegExp(r'\s+');

final _riceAndBeans = RegExp(r'^ARROZ( INTEGRAL)? E FEIJÃO$');

const _fruits = {
  'LARANJA', 'MAÇÃ', 'BANANA', 'MEXERICA', 'TANGERINA', 'PERA', 'PÊRA', //
  'MELANCIA', 'MAMÃO', 'ABACAXI', 'MELÃO', 'GOIABA', 'CAQUI',
};

const _dessertPrefixes = [
  'DOCE', 'BOMBOM', 'BARRA', 'PUDIM', 'GELATINA', 'MOUSSE', 'BOLO', //
  'PAÇOCA', 'SORVETE',
];
