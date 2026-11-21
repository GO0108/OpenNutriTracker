import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_plate_text.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_protein_map.dart';

import '../fixture/ru_fixtures.dart';

void main() {
  test('default RU tray', () {
    expect(
      ruMealToLogText(ruLunch),
      '120 g peito de frango cozido\n'
      '150 g arroz\n'
      '140 g feijão\n'
      '100 g creme de milho\n'
      '40 g salada de beterraba ralada\n'
      '1 laranja\n'
      '250 ml refresco de uva',
    );
  });

  test('RS gets the apple', () {
    expect(ruMealToLogText(ruLunch, restaurant: 'RS'), contains('1 maçã'));
  });

  test('vegan base, dessert, no main dish', () {
    const meal = RuMeal(
      kind: RuMealKind.veganDinner,
      title: 'Jantar Vegano',
      mainDish: null,
      items: ['ARROZ INTEGRAL E FEIJÃO', 'DOCE DE ABÓBORA'],
      notes: null,
    );
    expect(
      ruMealToLogText(meal),
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
    expect(parseMealText(text).items, hasLength(3));
  });

  test('bread is never added', () {
    expect(ruMealToLogText(ruLunch), isNot(contains('pão')));
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

  group('protein names', () {
    final cases = {
      'BISTECA SUÍNA ACEBOLADA': 'bisteca suína',
      'CUBOS SUÍNOS AO MOLHO': 'carne suína',
      'FRANGO EMPANADO': 'frango empanado',
      'FRANGO EM CUBOS COM LEGUMES': 'peito de frango cozido',
      'ISCAS DE FRANGO AO SHOYO': 'peito de frango cozido',
      'FRANGO ASSADO': 'frango assado',
      'SOBRECOXA DE FRANGO AO SUGO': 'sobrecoxa de frango',
      'STROGONOFF DE CARNE': 'estrogonofe de carne',
      'STROGONOFF DE FRANGO': 'estrogonofe de frango',
      'CARNE MOÍDA AO POMODORO': 'carne moída',
      'CARNE EM CUBOS AO MOLHO RÚSTICO': 'carne bovina cozida',
      'BIFE AO MOLHO DE CHAMPIGNON': 'bife',
      'PESCADA AO MOLHO DE ERVAS': 'peixe assado',
      'FILÉ DE PEIXE EMPANADO': 'peixe empanado',
      'FEIJOADA': 'feijoada',
      'LINGUIÇA TOSCANA ACEBOLADA': 'linguiça de porco',
    };
    cases.forEach((dish, name) {
      test(dish, () => expect(ruProteinName(dish), name));
    });

    test('vegan dishes keep their own name', () {
      expect(ruProteinName('CUBOS DE PTS EMPANADOS'), isNull);
      expect(ruProteinName('ALMÔNDEGA DE SOJA ASSADA'), isNull);
    });

    test('an unknown dish keeps its own name', () {
      expect(ruProteinName('TORTA DE MANDIOQUINHA'), isNull);
    });

    test('every protein name is a TACO alias', () {
      final aliases = <String>{
        for (final entry
            in (jsonDecode(File('tool/taco/taco_curation.json')
                        .readAsStringSync())
                    as Map)
                .values)
          ...((entry as Map)['aliases'] as List).cast<String>(),
      };
      for (final (_, name) in ruProteinRules) {
        if (name.isEmpty) continue;
        expect(aliases, contains(name), reason: name);
      }
    });
  });
}
