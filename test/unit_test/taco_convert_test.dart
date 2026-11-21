import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/taco/convert_taco.dart';

void main() {
  late List<Map<String, Object?>> records;
  Map<String, Object?> rec(int id) =>
      records.firstWhere((r) => r['id'] == id);

  setUpAll(() {
    String read(String path) => File('tool/taco/$path').readAsStringSync();
    records = convertTaco(
      foodCsv: read('data/food.csv'),
      nutrientsCsv: read('data/nutrients.csv'),
      fattyAcidsCsv: read('data/fatty-acids.csv'),
      curationJson: read('taco_curation.json'),
    );
  });

  test('all 597 foods', () => expect(records, hasLength(597)));

  test('cooked rice per 100 g', () {
    final r = rec(3);
    expect(r['name'], 'Arroz, tipo 1, cozido');
    expect(r['categoryId'], 1);
    expect(r['kcal'], 128.0);
    expect(r['protein'], 2.5);
    expect(r['fat'], 0.2);
    expect(r['carbs'], 28.1);
    expect(r['fiber'], 1.6);
    expect(r['sodium'], 1.0);
    expect(r['saturatedFat'], 0.2);
    expect(r['aliases'], containsAll(['arroz', 'arroz branco']));
  });

  test('blank cell is null, not zero', () {
    expect(rec(326)['fiber'], isNull);
  });

  test('trailing space in a name is trimmed', () {
    expect(rec(116)['name'], 'Couve, manteiga, refogada');
  });

  test('beans carry a 140 g ladle portion', () {
    final portions = (rec(561)['portions']! as List).cast<Map>();
    final ladle = portions.singleWhere((p) => p['en'] == 'ladle');
    expect(ladle['g'], 140.0);
  });

  test('every curated portion weighs between 1 and 1000 g', () {
    for (final r in records) {
      for (final p in (r['portions']! as List).cast<Map>()) {
        expect(p['g'] as num, inExclusiveRange(1, 1000));
      }
    }
  });

  test('committed asset matches the converter output', () {
    final asset = jsonDecode(
      File('assets/taco/taco.json').readAsStringSync(),
    );
    expect(asset, jsonDecode(jsonEncode(records)));
  });
}
