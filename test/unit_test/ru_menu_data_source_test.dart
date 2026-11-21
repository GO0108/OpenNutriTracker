import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/ru_menu/data/ru_menu_data_source.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';

void main() {
  final day = DateTime(2026, 11, 19);

  test('url is zero-padded', () {
    expect(
      RuMenuDataSource.urlFor(DateTime(2026, 3, 5)).toString(),
      'https://sistemas.prefeitura.unicamp.br/apps/cardapio/index.php'
      '?d=2026-03-05',
    );
  });

  test('ISO-8859-1 page decodes accents', () async {
    final client = MockClient(
      (_) async => http.Response.bytes(
        latin1.encode(
          '<h2>Almoço</h2><div>BIFE</div><ul><li>ARROZ E FEIJÃO</li></ul>',
        ),
        200,
        headers: {'content-type': 'text/html; charset=ISO-8859-1'},
      ),
    );
    final meals = await RuMenuDataSource(client).fetch(day);
    expect(meals.single.kind, RuMealKind.lunch);
    expect(meals.single.items.single, 'ARROZ E FEIJÃO');
  });

  test('UTF-8 page without a charset is read as UTF-8', () async {
    final client = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode('<h2>Jantar</h2><div>BIFE</div><p>ARROZ E FEIJÃO</p>'),
        200,
        headers: {'content-type': 'text/html'},
      ),
    );
    final meals = await RuMenuDataSource(client).fetch(day);
    expect(meals.single.items.single, 'ARROZ E FEIJÃO');
  });

  test('HTTP 500 gives an empty list', () async {
    final client = MockClient((_) async => http.Response('oops', 500));
    expect(await RuMenuDataSource(client).fetch(day), isEmpty);
  });

  test('network error gives an empty list', () async {
    final client = MockClient(
      (_) async => throw const SocketException('offline'),
    );
    expect(await RuMenuDataSource(client).fetch(day), isEmpty);
  });
}
