import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/taco_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/taco_food.dart';

import '../fixture/taco_fixtures.dart';

void main() {
  final source = TacoFoodDataSource([
    food(1, 'Arroz, integral, cozido', 1, aliases: ['arroz integral']),
    food(3, 'Arroz, tipo 1, cozido', 1,
        aliases: ['arroz', 'arroz branco'], kcal: 128),
    food(4, 'Arroz, tipo 1, cru', 1, kcal: 358),
    food(28, 'Creme de milho, pó', 1, kcal: 333),
    food(53, 'Pão, trigo, francês', 1, aliases: ['pão francês'], portions: [
      {'label': '1 unidade', 'en': 'piece', 'g': 50},
    ]),
    food(214, 'Laranja, pêra, crua', 3, aliases: ['laranja']),
    food(215, 'Laranja, pêra, suco', 3),
    food(326, 'Carne, bovina, acém, moído, cozido', 6),
    food(453, 'Leite, condensado', 7),
    food(471, 'Café, infusão 10%', 8),
    food(561, 'Feijão, carioca, cozido', 14, aliases: ['feijão']),
    food(562, 'Feijão, carioca, cru', 14),
  ]);
  List<String?> codes(String q) => source.search(q).map((m) => m.code).toList();

  test('alias wins: "arroz branco" is cooked white rice', () {
    expect(codes('arroz branco').first, 'taco:3');
  });

  test('"arroz" never returns raw rice', () {
    expect(codes('arroz'), isNot(contains('taco:4')));
    expect(codes('arroz').first, 'taco:3');
  });

  test('"arroz cru" does return raw rice', () {
    expect(codes('arroz cru').first, 'taco:4');
  });

  test('powder is only offered when asked for', () {
    expect(codes('creme de milho'), isEmpty);
    expect(codes('creme de milho em pó').first, 'taco:28');
  });

  test('accent-free query finds beans and bread', () {
    expect(codes('feijao').first, 'taco:561');
    expect(codes('pao frances').first, 'taco:53');
  });

  test('gender ending is optional: "carne moída" finds "acém, moído"', () {
    expect(codes('carne moída').first, 'taco:326');
  });

  test('fruit is not dropped by the raw filter', () {
    expect(codes('laranja').first, 'taco:214');
  });

  test('unrelated or stopword-only query returns nothing', () {
    expect(codes('pizza'), isEmpty);
    expect(codes('de'), isEmpty);
  });

  test('a lone generic word is a match but not a confident one', () {
    final leite = source.matches('leite');
    expect(leite.single.food.id, 453);
    expect(leite.single.confident, isFalse);
    expect(source.confidentMeals('leite'), isEmpty);
    expect(source.confidentMeals('feijão').single.code, 'taco:561');
  });

  test('fromTaco maps identity, units and portions', () {
    final m = source.search('pao frances').first;
    expect(m.source, MealSourceEntity.fdc);
    expect(m.backendSource, tacoSourceCode);
    expect(m.mealUnit, 'g');
    expect(m.servingQuantity, 50);
    expect(m.portions.single.englishLabel, 'piece');
    expect(m.nutriments.energyKcal100, 100);
    expect(source.search('cafe').first.mealUnit, 'ml');
  });

  test('the bundled asset loads and answers everyday queries', () async {
    final real = await _loadRealAsset();
    expect(real.foods, hasLength(597));
    expect(real.search('arroz').first.code, 'taco:3');
    expect(real.search('feijão').first.code, 'taco:561');
    expect(real.search('ovo frito').first.code, 'taco:490');
    expect(real.search('leite integral'), isEmpty);
  });
}

Future<TacoFoodDataSource> _loadRealAsset() async =>
    TacoFoodDataSource.loadFromAsset(_FileBundle());

class _FileBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      File(key).readAsString();
}
