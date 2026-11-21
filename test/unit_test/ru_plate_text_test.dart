import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_plate_text.dart';

import '../fixture/ru_fixtures.dart';

void main() {
  test('default RU tray', () {
    expect(
      ruMealToLogText(ruLunch),
      '120 g cubos de frango ao molho shoyu\n'
      '150 g arroz\n'
      '140 g feijão\n'
      '100 g creme de milho\n'
      '40 g salada de beterraba ralada\n'
      '1 laranja\n'
      '250 ml refresco de uva\n'
      '50 g pão francês',
    );
  });

  test('RS gets the apple', () {
    expect(ruMealToLogText(ruLunch, restaurant: 'RS'), contains('1 maçã'));
  });

  test('vegan base, dessert, no bread, no main dish', () {
    const meal = RuMeal(
      kind: RuMealKind.veganDinner,
      title: 'Jantar Vegano',
      mainDish: null,
      items: ['ARROZ INTEGRAL E FEIJÃO', 'DOCE DE ABÓBORA'],
      notes: null,
    );
    expect(
      ruMealToLogText(
        meal,
        defaults: const RuPlateDefaults(includeBread: false),
      ),
      '150 g arroz integral\n140 g feijão\n40 g doce de abóbora',
    );
  });

  test('commas inside a dish do not split it into two items', () {
    const meal = RuMeal(
      kind: RuMealKind.veganDinner,
      title: 'Jantar Vegano',
      mainDish: 'TORTA DE MANDIOQUINHA COM CENOURA, PTS E AVEIA',
      items: ['ARROZ INTEGRAL E FEIJÃO'],
      notes: null,
    );
    final text = ruMealToLogText(meal);
    expect(
      text.split('\n').first,
      '120 g torta de mandioquinha com cenoura pts e aveia',
    );
    expect(parseMealText(text).items, hasLength(4));
  });

  test('the offline parser reads every line with its amount', () {
    final result = parseMealText(ruMealToLogText(ruLunch));
    final byQuery = {for (final i in result.items) i.query: i};
    expect(byQuery['arroz']?.quantity, 150);
    expect(byQuery['arroz']?.unit, 'g');
    expect(byQuery['feijão']?.quantity, 140);
    expect(byQuery['refresco de uva']?.unit, 'ml');
    expect(byQuery['laranja']?.quantity, 1);
  });
}
