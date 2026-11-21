/// Brazilian Portuguese phrasing for the offline meal reader.
///
/// [parseMealText] is locale-neutral on purpose: it reads digits and unit
/// symbols and leaves every word to the food search. That is right for nine
/// locales and wrong for the way people actually talk in Portuguese — and
/// dictation is talking: "comi duas conchas de feijão e uma escumadeira de
/// arroz" reached the search as one query, with no number in it.
///
/// This layer runs first, only for a Portuguese UI, and only rewrites what it
/// is sure of:
///
/// * items joined by " e " are split ("arroz e feijão");
/// * leading chatter is dropped ("comi", "no almoço", "hoje");
/// * a leading number word becomes a digit ("duas", "meia", "uma e meia");
/// * unit words become symbols ("200 gramas" → "200 g", "meio litro" → 0.5 l);
/// * a household measure ("concha", "escumadeira", "copo", "fatia") is taken
///   out of the food name and handed on as [ParsedMealItem.portion], in the
///   English key the TACO and FDC portion labels are matched on.
///
/// No number is invented here. A measure only names which of the food's own
/// portions was meant; the grams still come from the food record, and a
/// measure the record does not have is ignored exactly as a model's key is.
library;

import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Item separators, as in [parseMealText]. A comma between two digits is a
/// decimal comma and is kept.
final _separator = RegExp(r'[;+\n、，；]|(?<!\d),|,(?!\d)');

/// " e " between two items. Not before "meio"/"meia": "uma e meia" is a
/// number.
final _and = RegExp(r'\s+e\s+(?!mei[oa]\b)', caseSensitive: false);

/// Food names that contain " e " and must not be split.
const _keepTogether = ['romeu e julieta'];

final _trailingPunctuation = RegExp(r'[.!?…]+$');

/// Chatter in front of the food, removed repeatedly from the start.
final _leadingFiller = RegExp(
  r'^(?:eu|hoje|agora|ontem|tamb[eé]m|s[oó]|apenas|mais|a[ií]|tipo|'
  r'ent[aã]o|comi|tomei|bebi|almocei|jantei|lanchei|belisquei|peguei|'
  r'uns|umas|um pouco de|um pouquinho de|'
  r'no caf[eé] da manh[aã]|de caf[eé] da manh[aã]|no caf[eé](?=\s+\S)|'
  r'no almo[cç]o|na janta|no jantar|no lanche|de manh[aã]|[aà] tarde|'
  r'[aà] noite|de almo[cç]o|de janta|de jantar|de lanche)\s+',
  caseSensitive: false,
  unicode: true,
);

const _numberWords = <String, double>{
  'um': 1,
  'uma': 1,
  'dois': 2,
  'duas': 2,
  'tres': 3,
  'três': 3,
  'quatro': 4,
  'cinco': 5,
  'seis': 6,
  'sete': 7,
  'oito': 8,
  'nove': 9,
  'dez': 10,
  'onze': 11,
  'doze': 12,
  'quinze': 15,
  'vinte': 20,
  'trinta': 30,
  'cem': 100,
  'duzentos': 200,
  'duzentas': 200,
  'trezentos': 300,
  'trezentas': 300,
  'quatrocentos': 400,
  'quatrocentas': 400,
  'quinhentos': 500,
  'quinhentas': 500,
};

const _numberWordPattern =
    r'(?:um|uma|dois|duas|tr[eê]s|quatro|cinco|seis|sete|oito|nove|dez|'
    r'onze|doze|quinze|vinte|trinta|cem|duzent[oa]s|trezent[oa]s|'
    r'quatrocent[oa]s|quinhent[oa]s)';

const _digits = r'\d+(?:[.,]\d+)?';

/// "meia dúzia de ovos", "uma dúzia de".
final _dozen = RegExp(
  '^(meia|uma|$_digits)\\s+d[uú]zias?\\s+(?:de\\s+)?',
  caseSensitive: false,
);

/// A leading number, as digits or a word, optionally "... e meio/meia".
final _leadingNumber = RegExp(
  '^($_digits|$_numberWordPattern)(\\s+e\\s+mei[oa])?(?=\\s|\$)\\s*',
  caseSensitive: false,
);

/// "meio pão", "meia xícara".
final _leadingHalf = RegExp(r'^mei[oa]\s+', caseSensitive: false);

/// Unit words and symbols, read after a number.
final _leadingUnit = RegExp(
  r'^(quilogramas?|quilos?|kg|gramas?|gr|g|mililitros?|ml|litros?|l)'
  r'(?=\s|$)\s*',
  caseSensitive: false,
);

const _unitSymbols = {
  'quilograma': 'kg',
  'quilogramas': 'kg',
  'quilo': 'kg',
  'quilos': 'kg',
  'kg': 'kg',
  'grama': 'g',
  'gramas': 'g',
  'gr': 'g',
  'g': 'g',
  'mililitro': 'ml',
  'mililitros': 'ml',
  'ml': 'ml',
  'litro': 'l',
  'litros': 'l',
  'l': 'l',
};

/// Household measures and the English portion key each one names. Order
/// matters: the specific spoons before the bare one.
///
/// A measure counts only when "de" follows it — "uma concha de feijão" —
/// so a food whose name merely starts with one of these words is left alone.
final _measures = <(RegExp, String)>[
  (_measure(r'colher(?:es|zinhas?)? de ch[aá]'), 'teaspoon'),
  (_measure(r'colher(?:es)? de sopa'), 'tablespoon'),
  (_measure(r'colher(?:es)? de sobremesa'), 'spoon'),
  (_measure(r'colher(?:es)? de servir'), 'spoon'),
  (_measure(r'colher(?:es)?'), 'spoon'),
  (_measure(r'conchas?'), 'ladle'),
  (_measure(r'escumadeiras?'), 'skimmer'),
  (_measure(r'copos?(?: americanos?)?'), 'cup'),
  (_measure(r'x[ií]caras?'), 'cup'),
  (_measure(r'canecas?'), 'mug'),
  (_measure(r'fatias?'), 'slice'),
  (_measure(r'peda[cç]os?'), 'piece'),
  (_measure(r'unidades?'), 'piece'),
  (_measure(r'fil[eé]s?'), 'piece'),
  (_measure(r'por[cç](?:[aã]o|[oõ]es)'), 'serving'),
  (_measure(r'pratos?'), 'plate'),
  (_measure(r'tigelas?|cumbucas?|potes?'), 'bowl'),
  (_measure(r'latas?|latinhas?'), 'can'),
  (_measure(r'garrafas?|garrafinhas?'), 'bottle'),
  (_measure(r'bolas?'), 'scoop'),
  (_measure(r'punhados?'), 'handful'),
];

/// A size word right after the measure ("uma concha cheia de", "uma fatia
/// grande de"). The size reaches the key; fullness words are dropped.
const _sizeWords =
    r'(?:\s+(cheia|cheio|rasa|raso|grande|grandes|pequena|pequenas|pequeno|'
    r'pequenos|m[eé]dia|m[eé]dio|bem servida|bem servido))?';

RegExp _measure(String words) => RegExp(
  '^(?:$words)$_sizeWords\\s+(?:de|do|da|dos|das)\\s+',
  caseSensitive: false,
  unicode: true,
);

String? _sizeKey(String? word) {
  if (word == null) return null;
  final w = word.toLowerCase();
  if (w.startsWith('grande')) return 'large';
  if (w.startsWith('pequen')) return 'small';
  if (w.startsWith('m')) return 'medium';
  return null;
}

/// "de"/"do"/"da" right after a unit: "200 g de arroz".
final _leadingOf = RegExp(r'^(?:de|do|da|dos|das)\s+', caseSensitive: false);

/// A digit glued or spaced to a unit word anywhere in the text: "arroz 150
/// gramas" → "arroz 150 g".
final _digitUnitWord = RegExp(
  '($_digits)\\s*(quilogramas?|quilos?|gramas?|gr|mililitros?|litros?)'
  '(?=\\s|\$|[,;.])',
  caseSensitive: false,
);

/// A number glued to a unit symbol at the start: "200g de arroz".
final _gluedUnit = RegExp(
  '^($_digits)(kg|gr|g|ml|l)(?=\\s|\$)',
  caseSensitive: false,
);

/// "200 g" / "duzentos gramas" / "meio litro" at the start of an item: the
/// text [textStatesAUnit] checks when the input is Portuguese, so a model
/// reporting the gram of "200 gramas de arroz" is believed.
String ptUnitWordsToSymbols(String input) => input
    .split(_separator)
    .expand(_splitItems)
    .map((segment) {
      final item = _readSegment(segment);
      return item.unit == null ? segment : item.text;
    })
    .join('\n');

/// One item after the Portuguese rewrite: [text] is what [parseMealText]
/// reads, [portionKey] the measure it named.
class _PtItem {
  final String text;
  final double? quantity;
  final String? unit;
  final String? portionKey;

  const _PtItem(this.text, {this.quantity, this.unit, this.portionKey});
}

/// Whether [part] starts with an explicit weight or volume — "100 g", "250
/// ml", "200 gramas". The " e " rule keys off it.
bool _startsWithWeight(String part) {
  final item = _readSegment(part);
  return item.unit != null;
}

/// Splits one separator-delimited segment on " e ".
///
/// Not after an explicit weight unless the next part has a quantity of its
/// own: "100 g torta de mandioquinha com cenoura e aveia" is one RU dish,
/// with one weight, while "duas conchas de feijão e um bife" is two items.
Iterable<String> _splitItems(String segment) sync* {
  var text = segment.trim().replaceAll(_trailingPunctuation, '').trim();
  if (text.isEmpty) return;
  final lower = text.toLowerCase();
  if (_keepTogether.any(lower.contains)) {
    yield text;
    return;
  }
  final parts = text
      .split(_and)
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return;
  var current = parts.first;
  for (final next in parts.skip(1)) {
    if (_startsWithWeight(current) && !_hasQuantity(next)) {
      current = '$current e $next';
    } else {
      yield current;
      current = next;
    }
  }
  yield current;
}

/// Whether [part] states an amount of its own: a number, a number word, or
/// a measure.
bool _hasQuantity(String part) => _readSegment(part).quantity != null;

String _stripFillers(String text) {
  var t = text.trim();
  while (true) {
    final m = _leadingFiller.firstMatch(t);
    if (m == null) return t;
    t = t.substring(m.end).trim();
  }
}

String _formatNumber(double n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toString();

double _numberOf(String raw) {
  final key = raw.toLowerCase();
  return _numberWords[key] ?? double.parse(raw.replaceAll(',', '.'));
}

/// Reads one item: chatter, number, unit, measure, "de", food.
_PtItem _readSegment(String segment) {
  var rest = _stripFillers(
    segment.trim().replaceAll(_trailingPunctuation, '').trim(),
  )
      .replaceAllMapped(
        _digitUnitWord,
        (m) => '${m[1]} ${_unitSymbols[m[2]!.toLowerCase()]}',
      )
      .replaceFirstMapped(_gluedUnit, (m) => '${m[1]} ${m[2]}');

  double? quantity;
  String? unit;
  String? portionKey;

  final dozen = _dozen.firstMatch(rest);
  if (dozen != null) {
    final raw = dozen[1]!.toLowerCase();
    final dozens = raw == 'meia' ? 0.5 : (raw == 'uma' ? 1.0 : _numberOf(raw));
    quantity = dozens * 12;
    rest = rest.substring(dozen.end);
  } else {
    final number = _leadingNumber.firstMatch(rest);
    if (number != null) {
      quantity = _numberOf(number[1]!) + (number[2] != null ? 0.5 : 0);
      rest = rest.substring(number.end);
    } else {
      final half = _leadingHalf.firstMatch(rest);
      if (half != null) {
        quantity = 0.5;
        rest = rest.substring(half.end);
      }
    }
  }

  // A unit word only counts after a number ("200 gramas"), except a bare
  // "litro"/"quilo", which means one: "um litro" was already read above.
  final unitMatch = _leadingUnit.firstMatch(rest);
  if (unitMatch != null &&
      (quantity != null ||
          RegExp(r'^(?:litro|quilo)', caseSensitive: false)
              .hasMatch(unitMatch[1]!))) {
    unit = _unitSymbols[unitMatch[1]!.toLowerCase()];
    quantity ??= 1;
    rest = rest.substring(unitMatch.end);
    final of = _leadingOf.firstMatch(rest);
    if (of != null) rest = rest.substring(of.end);
  } else {
    for (final (pattern, key) in _measures) {
      final m = pattern.firstMatch(rest);
      if (m == null) continue;
      final size = _sizeKey(m[1]);
      portionKey = size == null ? key : '$size $key';
      quantity ??= 1;
      rest = rest.substring(m.end);
      break;
    }
  }

  rest = rest.trim();
  if (quantity == null) return _PtItem(rest);
  final amount = _formatNumber(quantity);
  final text = unit == null ? '$amount $rest' : '$amount $unit $rest';
  return _PtItem(
    text.trim(),
    quantity: quantity,
    unit: unit,
    portionKey: portionKey,
  );
}

/// [parseMealText] for a Portuguese UI: the same result shape and the same
/// bounds, with the rewrite above applied first and the measure carried on
/// [ParsedMealItem.portion].
MealTextParseResult parsePtMealText(String input) {
  final pieces = <_PtItem>[
    for (final segment in input.trim().split(_separator))
      for (final part in _splitItems(segment)) _readSegment(part),
  ].where((p) => p.text.isNotEmpty).toList();

  // One line per item, so the parser's numbering is ours: item N of its
  // result is pieces[N - 1].
  final parsed = parseMealText(pieces.map((p) => p.text).join('\n'));
  final rejected = {for (final e in parsed.errors) e.itemNumber};

  final items = <ParsedMealItem>[];
  var next = 0;
  for (var i = 0; i < pieces.length; i++) {
    if (rejected.contains(i + 1)) continue;
    final item = parsed.items[next++];
    items.add(
      ParsedMealItem(
        query: item.query,
        quantity: item.quantity,
        unit: item.unit,
        portion: item.quantity == null ? null : pieces[i].portionKey,
      ),
    );
  }
  return MealTextParseResult(items: items, errors: parsed.errors);
}

/// Whether the UI language is one this layer reads.
bool isPortugueseLocale(String? localeCode) =>
    localeCode != null && localeCode.toLowerCase().startsWith('pt');
