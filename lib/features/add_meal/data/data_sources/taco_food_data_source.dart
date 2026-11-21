import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/taco_food.dart';

/// One search hit and how sure the search is about it.
class TacoMatch {
  final TacoFood food;

  /// 2.0 for a curated alias, otherwise the share (0–1) of the query's
  /// words found in the food's name.
  final double score;

  /// True when the hit is safe to put ahead of other databases: an alias,
  /// or every word of a query of two or more words found in the name.
  /// A lone generic word ("leite") matches a whole family — condensed,
  /// fermented, goat — and the shortest name is not the likeliest meaning,
  /// so such hits compete on the normal ranking instead.
  final bool confident;

  const TacoMatch(this.food, this.score, {required this.confident});

  MealEntity toMeal() => MealEntity.fromTaco(food);
}

/// The Brazilian food composition table (TACO), bundled and searched on the
/// device: no network, no rate limit, Portuguese names.
///
/// Search is tuned for how people *say* what they ate in Portuguese:
/// - accents and gender/plural endings are optional ("feijao" finds
///   "Feijão", "carne moída" finds "acém, moído");
/// - curated aliases pin the everyday reading ("arroz" is cooked white
///   rice, "bife" a grilled steak);
/// - a raw variant of a food normally eaten cooked, and powders, are never
///   offered unless the query asks for them — "Arroz, tipo 1, cru" has
///   358 kcal/100 g against 128 for cooked, and "Creme de milho, pó" 333,
///   so picking either silently would multiply the logged energy;
/// - foods TACO lists without an energy value are left out: they cannot be
///   logged meaningfully.
class TacoFoodDataSource {
  static const assetPath = 'assets/taco/taco.json';

  /// TACO categories whose raw rows are ingredients, not plates: cereals,
  /// fish, meat, eggs and legumes. Vegetables and fruit are left out on
  /// purpose — salad and fruit are eaten raw.
  static const _cookedCategories = {1, 5, 6, 9, 14};

  static const _rawTokens = {'cru', 'crua', 'crus', 'cruas'};

  static const _powderToken = 'po';

  static const _saladToken = 'salada';

  static const _stopwords = {
    'de', 'da', 'do', 'das', 'dos', 'com', 'e', 'a', 'o', 'em', 'ao', //
    'na', 'no', 'um', 'uma',
  };

  /// A query word also matches a name word that extends or shortens it by
  /// at most this many letters, after stemming — "franc" ↔ "frances".
  static const _maxInflection = 2;

  /// At least this share of the query's words must be in the name. 0.6
  /// means both words of a two-word query, two of three, three of four.
  static const _minScore = 0.6;
  static const _aliasScore = 2.0;

  final List<TacoFood> _foods;
  final List<_Indexed> _index;

  TacoFoodDataSource(List<TacoFood> foods)
    : _foods = List.unmodifiable(foods),
      _index = [
        for (final food in foods)
          if (food.kcal != null) _Indexed.of(food),
      ];

  static Future<TacoFoodDataSource> loadFromAsset(AssetBundle bundle) async {
    final raw = await bundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    return TacoFoodDataSource([
      for (final item in list)
        TacoFood.fromJson((item as Map).cast<String, Object?>()),
    ]);
  }

  List<TacoFood> get foods => _foods;

  /// Best matches first, as meals ready for the search lists. Empty for a
  /// query with no content words.
  List<MealEntity> search(String query, {int limit = 10}) => [
    for (final match in matches(query, limit: limit)) match.toMeal(),
  ];

  /// The meals [search] would return that are [TacoMatch.confident].
  List<MealEntity> confidentMeals(String query, {int limit = 10}) => [
    for (final match in matches(query, limit: limit))
      if (match.confident) match.toMeal(),
  ];

  List<TacoMatch> matches(String query, {int limit = 10}) {
    final queryTokens = tokens(query);
    if (queryTokens.isEmpty) return const [];
    final queryKey = queryTokens.join(' ');
    final wantsRaw = queryTokens.any(_rawTokens.contains);
    final wantsPowder = queryTokens.contains(_powderToken);
    // "salada de beterraba" is beetroot served as salad: TACO names the
    // vegetable, so the dish word may be dropped when something follows it.
    final variants = [
      queryTokens.map(_stem).toList(),
      if (queryTokens.length > 1 && queryTokens.first == _saladToken)
        queryTokens.skip(1).map(_stem).toList(),
    ];

    final hits = <(_Indexed, double)>[];
    for (final entry in _index) {
      if (!wantsRaw &&
          _cookedCategories.contains(entry.food.categoryId) &&
          entry.rawTokens.any(_rawTokens.contains)) {
        continue;
      }
      if (!wantsPowder && entry.rawTokens.contains(_powderToken)) continue;
      var score = 0.0;
      if (entry.aliasKeys.contains(queryKey)) {
        score = _aliasScore;
      } else {
        for (final variant in variants) {
          final s = _nameScore(variant, entry.stems);
          if (s > score) score = s;
        }
      }
      if (score >= _minScore) hits.add((entry, score));
    }

    hits.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      final byLength = a.$1.stems.length.compareTo(b.$1.stems.length);
      if (byLength != 0) return byLength;
      return a.$1.food.id.compareTo(b.$1.food.id);
    });

    return [
      for (final (entry, score) in hits.take(limit))
        TacoMatch(
          entry.food,
          score,
          confident:
              score == _aliasScore ||
              (score >= 1.0 && queryTokens.length >= 2),
        ),
    ];
  }

  /// Share of the query's words found in the name; zero unless the query's
  /// first word — the food itself, in Portuguese word order — is the name's
  /// first word too. TACO names lead with the family ("Leite, condensado"),
  /// so "leite integral" must not land on "Canjica, com leite integral".
  static double _nameScore(List<String> query, List<String> name) {
    bool found(String q) => name.any((n) => _matches(q, n));
    if (name.isEmpty || !_matches(query.first, name.first)) return 0;
    final matched = query.where(found).length;
    return matched / query.length;
  }

  static bool _matches(String a, String b) {
    if (a == b) return true;
    final (short, long) = a.length <= b.length ? (a, b) : (b, a);
    return short.length >= 3 &&
        long.startsWith(short) &&
        long.length - short.length <= _maxInflection;
  }

  /// Drops a plural "s" and then a gender "a"/"o", so "moída", "moído",
  /// "cozidas" and "cozido" all meet at "moid"/"cozid".
  static String _stem(String token) {
    var t = token;
    if (t.length > 3 && t.endsWith('s')) t = t.substring(0, t.length - 1);
    if (t.length > 3 && (t.endsWith('a') || t.endsWith('o'))) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  /// Lower-case, accent-free content words of [text].
  static List<String> tokens(String text) => normalize(text)
      .split(' ')
      .where((t) => t.isNotEmpty && !_stopwords.contains(t))
      .toList();

  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };

  static final _nonWord = RegExp(r'[^a-z0-9]+');

  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(_nonWord, ' ').trim();
  }
}

class _Indexed {
  final TacoFood food;
  final List<String> rawTokens;
  final List<String> stems;
  final Set<String> aliasKeys;

  const _Indexed(this.food, this.rawTokens, this.stems, this.aliasKeys);

  factory _Indexed.of(TacoFood food) {
    final tokens = TacoFoodDataSource.tokens(food.name);
    return _Indexed(
      food,
      tokens,
      tokens.map(TacoFoodDataSource._stem).toList(),
      {
        for (final alias in food.aliases)
          TacoFoodDataSource.tokens(alias).join(' '),
      },
    );
  }
}
