import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/ru_menu/data/ru_menu_parser.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';

import '../fixture/ru_fixtures.dart';

void main() {
  test('synthetic page: three meals with kinds, dishes, items, notes', () {
    final meals = parseRuMenuHtml(ruSyntheticPage);
    expect(meals.map((m) => m.kind), [
      RuMealKind.lunch,
      RuMealKind.veganLunch,
      RuMealKind.dinner,
    ]);
    expect(meals[0].title, 'Almoço');
    expect(meals[0].mainDish, 'CUBOS DE FRANGO AO MOLHO SHOYU');
    expect(meals[0].items, hasLength(5));
    expect(meals[0].notes, startsWith('CONTÉM GLÚTEN'));
    expect(meals[1].mainDish, 'ENSOPADO DE ERVILHAS COM BRÓCOLIS');
    expect(meals[2].mainDish, isNull);
    expect(meals[2].items.first, 'ARROZ E FEIJÃO');
  });

  test('notes starting mid-line are split from the last item', () {
    final meals = parseRuMenuHtml(
      '<h3>Jantar</h3><p>BIFE</p><p>ARROZ E FEIJÃO</p>'
      '<p>REFRESCO DE UVA Observações: CONTÉM GLÚTEN</p>',
    );
    expect(meals.single.items, ['ARROZ E FEIJÃO', 'REFRESCO DE UVA']);
    expect(meals.single.notes, 'CONTÉM GLÚTEN');
  });

  test('entities and line breaks are read as text', () {
    final meals = parseRuMenuHtml(
      '<div>Almo&ccedil;o</div><div>BIFE<br>ARROZ E FEIJ&Atilde;O</div>',
    );
    expect(meals.single.kind, RuMealKind.lunch);
    expect(meals.single.items.single, 'ARROZ E FEIJÃO');
  });

  test('empty or menu-less page yields no meals', () {
    expect(parseRuMenuHtml(''), isEmpty);
    expect(
      parseRuMenuHtml('<html><body>Sem cardápio</body></html>'),
      isEmpty,
    );
  });

  // Copies of the real Prefeitura page (fetched by CI, converted from
  // ISO-8859-1 to UTF-8). The 17th labels its notes "Observações:", the 19th
  // does not; both must read the same way.
  group('real Prefeitura pages', () {
    List<RuMeal> page(String day) => parseRuMenuHtml(
      File('test/fixture/ru/cardapio_$day.html').readAsStringSync(),
    );

    test('2026-11-19: four services, notes without a label', () {
      final meals = page('2026-11-19');
      expect(meals.map((m) => m.kind), [
        RuMealKind.lunch,
        RuMealKind.veganLunch,
        RuMealKind.dinner,
        RuMealKind.veganDinner,
      ]);
      final lunch = meals.first;
      expect(lunch.mainDish, 'FRANGO ASSADO');
      expect(lunch.items, [
        'ARROZ E FEIJÃO',
        'FAROFA CROCANTE (FARINHA DE MANDIOCA E BATATA PALHA)',
        'SALADA DE ALFACE',
        'BANANA (RS - HC COTUCA); LARANJA (RU)',
        'REFRESCO DE CAJU',
      ]);
      expect(lunch.notes, startsWith('CONTÉM GLÚTEN NO PÃO.'));
      expect(meals.last.mainDish,
          'TORTA DE MANDIOQUINHA COM CENOURA, PTS E AVEIA');
      expect(meals.last.items, contains('MAÇÃ'));
    });

    test('2026-11-17: labelled notes stay out of the items', () {
      final meals = page('2026-11-17');
      expect(meals, hasLength(4));
      expect(meals[2].mainDish, 'CARNE MOÍDA AO POMODORO');
      expect(meals[2].items, [
        'ARROZ E FEIJÃO',
        'MACARRÃO AO ALHO E ÓLEO',
        'SALADA DE COUVE',
        'MAÇÃ',
        'REFRESCO DE MORANGO',
      ]);
      expect(meals[2].notes, startsWith('CONTÉM GLÚTEN'));
    });
  });

  group('pickRestaurantVariant', () {
    test('slash', () {
      expect(pickRestaurantVariant('LARANJA (RU, RA e HC) / MAÇÃ (RS)'),
          'LARANJA');
      expect(
        pickRestaurantVariant(
          'LARANJA (RU, RA e HC) / MAÇÃ (RS)',
          restaurant: 'RS',
        ),
        'MAÇÃ',
      );
    });

    test('pipe', () {
      expect(
        pickRestaurantVariant('DOCE DE GOIABA (RA/RS/HC) | DOCE DE BANANA (RU)'),
        'DOCE DE BANANA',
      );
    });

    test('no separator', () {
      expect(
        pickRestaurantVariant(
          'ABOBRINHA REFOGADA (RS/RA E HC) COUVE REFOGADA (RU)',
        ),
        'COUVE REFOGADA',
      );
    });

    test('no annotation', () {
      expect(pickRestaurantVariant('SALADA DE ALFACE'), 'SALADA DE ALFACE');
    });

    test('semicolon with a dash-separated list', () {
      expect(
        pickRestaurantVariant('BANANA (RS - HC COTUCA); LARANJA (RU)'),
        'LARANJA',
      );
      expect(
        pickRestaurantVariant(
          'BANANA (RS - HC COTUCA); LARANJA (RU)',
          restaurant: 'RS',
        ),
        'BANANA',
      );
    });

    test('a description in parentheses is dropped, not read as a list', () {
      expect(
        pickRestaurantVariant(
          'FAROFA CROCANTE (FARINHA DE MANDIOCA E BATATA PALHA)',
        ),
        'FAROFA CROCANTE',
      );
    });

    test('no match falls back to the first variant', () {
      expect(pickRestaurantVariant('MAÇÃ (HC/CAISM)'), 'MAÇÃ');
    });
  });
}
