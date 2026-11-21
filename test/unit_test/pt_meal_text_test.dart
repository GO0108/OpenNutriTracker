import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/pt_meal_text.dart';

void main() {
  void expectItem(
    ParsedMealItem item,
    String query, {
    double? quantity,
    String? unit,
    String? portion,
  }) {
    expect(item.query, query);
    expect(item.quantity, quantity);
    expect(item.unit, unit);
    expect(item.portion, portion);
  }

  group('parsePtMealText household measures', () {
    test('spoken sentence with two measures', () {
      final r = parsePtMealText(
        'comi duas conchas de feijão e uma escumadeira de arroz',
      );
      expect(r.errors, isEmpty);
      expect(r.items, hasLength(2));
      expectItem(r.items[0], 'feijão', quantity: 2, portion: 'ladle');
      expectItem(r.items[1], 'arroz', quantity: 1, portion: 'skimmer');
    });

    test('cup, slice with size, fillet', () {
      final r = parsePtMealText(
        'um copo de leite; uma fatia grande de pão; um filé de frango',
      );
      expectItem(r.items[0], 'leite', quantity: 1, portion: 'cup');
      expectItem(r.items[1], 'pão', quantity: 1, portion: 'large slice');
      expectItem(r.items[2], 'frango', quantity: 1, portion: 'piece');
    });

    test('spoons', () {
      final r = parsePtMealText(
        'duas colheres de sopa de azeite, uma colher de chá de açúcar, '
        'três colheres de arroz',
      );
      expectItem(r.items[0], 'azeite', quantity: 2, portion: 'tablespoon');
      expectItem(r.items[1], 'açúcar', quantity: 1, portion: 'teaspoon');
      expectItem(r.items[2], 'arroz', quantity: 3, portion: 'spoon');
    });

    test('a measure word without "de" stays in the name', () {
      final r = parsePtMealText('filé mignon');
      expectItem(r.items.single, 'filé mignon');
    });
  });

  group('parsePtMealText numbers and units', () {
    test('number words become digits', () {
      final r = parsePtMealText('dois ovos fritos');
      expectItem(r.items.single, 'ovos fritos', quantity: 2);
    });

    test('halves and dozens', () {
      final r = parsePtMealText(
        'meio pão francês, meia dúzia de ovos, uma e meia xícara de leite',
      );
      expectItem(r.items[0], 'pão francês', quantity: 0.5);
      expectItem(r.items[1], 'ovos', quantity: 6);
      expectItem(r.items[2], 'leite', quantity: 1.5, portion: 'cup');
    });

    test('unit words become symbols', () {
      final r = parsePtMealText(
        '200 gramas de arroz\nduzentos gramas de frango\n'
        'meio litro de suco de laranja\n200g de batata\narroz 150 gramas',
      );
      expectItem(r.items[0], 'arroz', quantity: 200, unit: 'g');
      expectItem(r.items[1], 'frango', quantity: 200, unit: 'g');
      expectItem(r.items[2], 'suco de laranja', quantity: 500, unit: 'ml');
      expectItem(r.items[3], 'batata', quantity: 200, unit: 'g');
      expectItem(r.items[4], 'arroz', quantity: 150, unit: 'g');
    });

    test('a bare litre means one', () {
      final r = parsePtMealText('litro de leite');
      expectItem(r.items.single, 'leite', quantity: 1000, unit: 'ml');
    });
  });

  group('parsePtMealText splitting and chatter', () {
    test('" e " separates items, chatter is dropped', () {
      final r = parsePtMealText('no almoço arroz, feijão e bife.');
      expect(r.items.map((i) => i.query), ['arroz', 'feijão', 'bife']);
      expect(r.items.every((i) => i.quantity == null), isTrue);
    });

    test('a weighed RU dish keeps its " e "', () {
      final r = parsePtMealText(
        '100 g torta de mandioquinha com cenoura pts e aveia',
      );
      expectItem(
        r.items.single,
        'torta de mandioquinha com cenoura pts e aveia',
        quantity: 100,
        unit: 'g',
      );
    });

    test('a weighed item still splits when the next has an amount', () {
      final r = parsePtMealText('150 g arroz e 1 concha de feijão');
      expectItem(r.items[0], 'arroz', quantity: 150, unit: 'g');
      expectItem(r.items[1], 'feijão', quantity: 1, portion: 'ladle');
    });

    test('romeu e julieta is one food', () {
      expectItem(parsePtMealText('romeu e julieta').items.single,
          'romeu e julieta');
    });

    test('RU plate text passes through unchanged', () {
      final r = parsePtMealText(
        '120 g bisteca suína\n150 g arroz\n140 g feijão\n40 g salada de '
        'alface\n250 ml suco de caju\n1 laranja',
      );
      expect(r.errors, isEmpty);
      expect(r.items.map((i) => i.query), [
        'bisteca suína',
        'arroz',
        'feijão',
        'salada de alface',
        'suco de caju',
        'laranja',
      ]);
      expect(r.items.last.quantity, 1);
      expect(r.items.every((i) => i.portion == null), isTrue);
    });

    test('a single drink', () {
      expectItem(parsePtMealText('tomei um café').items.single, 'café',
          quantity: 1);
    });
  });

  group('parsePtMealText errors keep their numbering', () {
    test('zero and nameless items', () {
      final r = parsePtMealText('2 ovos, 123, 0 g de sal');
      expectItem(r.items.single, 'ovos', quantity: 2);
      expect(r.errors, [
        const InvalidFoodNameError(2),
        const QuantityTooSmallError(3),
      ]);
    });
  });

  group('Portuguese units in textStatesAUnit', () {
    test('a unit word is a stated unit', () {
      expect(textStatesAUnit('200 gramas de arroz'), isTrue);
      expect(textStatesAUnit('meio litro de suco'), isTrue);
    });

    test('a household measure is not', () {
      expect(textStatesAUnit('um copo de leite'), isFalse);
      expect(textStatesAUnit('duas conchas de feijão'), isFalse);
    });
  });

  test('isPortugueseLocale', () {
    expect(isPortugueseLocale('pt'), isTrue);
    expect(isPortugueseLocale('pt_BR'), isTrue);
    expect(isPortugueseLocale('en'), isFalse);
    expect(isPortugueseLocale(null), isFalse);
  });
}
