import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/ru_menu/data/ru_menu_parser.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';

/// Fetches the day's menu of the Unicamp university restaurants from the
/// Prefeitura's public page.
///
/// Never throws: a weekend, a holiday, a page that moved, no signal on the
/// way to the bandejão — all of them come back as an empty list, which the
/// sheet shows as "no menu for this day".
class RuMenuDataSource {
  static final _log = Logger('RuMenuDataSource');
  static const timeout = Duration(seconds: 15);

  final http.Client _client;

  RuMenuDataSource(this._client);

  static Uri urlFor(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = '${day.year}-${two(day.month)}-${two(day.day)}';
    return Uri.parse(
      'https://sistemas.prefeitura.unicamp.br/apps/cardapio/index.php?d=$d',
    );
  }

  Future<List<RuMeal>> fetch(DateTime day) async {
    try {
      final response = await _client.get(urlFor(day)).timeout(timeout);
      if (response.statusCode != 200) {
        _log.warning('RU menu HTTP ${response.statusCode}');
        return const [];
      }
      return parseRuMenuHtml(decodeBody(response));
    } catch (e, stackTrace) {
      _log.warning('RU menu unavailable', e, stackTrace);
      return const [];
    }
  }

  /// The page as text, in the charset its `content-type` declares. Older
  /// PHP pages at the university still answer in ISO-8859-1, where reading
  /// the bytes as UTF-8 would turn "ALMOÇO" into "ALMO�O" and the headings
  /// would no longer match.
  static String decodeBody(http.Response response) {
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    final latin = ['iso-8859-1', 'latin1', 'latin-1', 'windows-1252'];
    if (latin.any(type.contains)) return latin1.decode(response.bodyBytes);
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}
