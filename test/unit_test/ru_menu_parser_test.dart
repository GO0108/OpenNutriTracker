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

  // A copy of the real page, saved by CI (tool/ru/fetch_sample.sh). Skipped
  // until one is committed; it guards the parser against the live markup.
  final real = File('test/fixture/ru/cardapio_sample.html');
  test(
    'real Prefeitura page parses into lunch and dinner with beans',
    () {
      final meals = parseRuMenuHtml(real.readAsStringSync());
      expect(meals.map((m) => m.kind), contains(RuMealKind.lunch));
      expect(meals.map((m) => m.kind), contains(RuMealKind.dinner));
      for (final m in meals) {
        expect(
          m.items.any((i) => i.toUpperCase().contains('FEIJ')),
          isTrue,
          reason: '${m.title}: ${m.items}',
        );
      }
    },
    skip: real.existsSync() ? false : 'no saved page yet',
  );

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

    test('no match falls back to the first variant', () {
      expect(pickRestaurantVariant('MAÇÃ (HC/CAISM)'), 'MAÇÃ');
    });
  });
}
