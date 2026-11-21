import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';

/// Reads the Prefeitura da Unicamp menu page
/// (`sistemas.prefeitura.unicamp.br/apps/cardapio/index.php?d=…`) into its
/// services.
///
/// Works on text, not on the page's markup: block-level tags become line
/// breaks, every other tag is dropped, and the lines are read as headings
/// ("Almoço", "Jantar Vegano"…), a main dish, plate items, and an
/// "Observações:" tail. That keeps it working when the page's CSS classes
/// change, which they have over the years, as long as the words stay.
List<RuMeal> parseRuMenuHtml(String html) {
  final lines = htmlToLines(html);
  final meals = <RuMeal>[];

  RuMealKind? kind;
  String? title;
  String? mainDish;
  var items = <String>[];
  final notes = <String>[];
  var inNotes = false;
  var expectMain = false;

  void flush() {
    final k = kind;
    if (k == null) return;
    if (mainDish != null || items.isNotEmpty) {
      meals.add(
        RuMeal(
          kind: k,
          title: title!,
          mainDish: mainDish,
          items: List.unmodifiable(items),
          notes: notes.isEmpty ? null : notes.join(' '),
        ),
      );
    }
  }

  void read(String line) {
    final heading = _heading.firstMatch(line);
    if (heading != null) {
      flush();
      kind = _kindOf(heading.group(1)!, vegan: heading.group(2) != null);
      title = line;
      mainDish = null;
      items = <String>[];
      notes.clear();
      inNotes = false;
      expectMain = true;
      return;
    }
    if (kind == null) return;
    if (_pageEnd.hasMatch(line)) {
      flush();
      kind = null;
      return;
    }

    final notesStart = _notes.firstMatch(line);
    if (notesStart != null && notesStart.start == 0) {
      inNotes = true;
      final rest = line.substring(notesStart.end).trim();
      if (rest.isNotEmpty) notes.add(rest);
      return;
    }
    // Some days carry no "Observações:" label and the allergen notes simply
    // follow the last item; they read as sentences, the items do not.
    if (!inNotes && _noteSentence.hasMatch(line)) inNotes = true;
    if (inNotes) {
      notes.add(line);
      return;
    }
    if (expectMain) {
      expectMain = false;
      if (!line.toUpperCase().startsWith('ARROZ')) {
        mainDish = line;
        return;
      }
    }
    items.add(line);
  }

  for (final line in lines) {
    // "REFRESCO DE UVA Observações: CONTÉM GLÚTEN" — the notes may start
    // mid-line, after the last item.
    final notesAt = _notes.firstMatch(line);
    if (notesAt != null && notesAt.start > 0) {
      read(line.substring(0, notesAt.start).trim());
      read(line.substring(notesAt.start));
    } else {
      read(line);
    }
  }
  flush();
  return meals;
}

/// The one variant of [item] served at [restaurant].
///
/// The page writes per-restaurant alternatives in several ways —
/// "LARANJA (RU, RA e HC) / MAÇÃ (RS)", "BANANA (RS - HC COTUCA); LARANJA
/// (RU)", "DOCE DE GOIABA (RA/RS/HC) | DOCE DE BANANA (RU)" and, with no
/// separator at all, "ABOBRINHA REFOGADA (RS/RA E HC) COUVE REFOGADA (RU)".
/// Each name is followed by its restaurants in parentheses. When none lists
/// [restaurant] the first is taken.
///
/// Parentheses that are not a restaurant list — "FAROFA CROCANTE (FARINHA
/// DE MANDIOCA E BATATA PALHA)" — describe the dish and are dropped.
String pickRestaurantVariant(String item, {String restaurant = 'RU'}) {
  final cleaned = item
      .replaceAllMapped(
        _parenthetical,
        (m) => _isRestaurantList(m.group(1)!) ? m.group(0)! : ' ',
      )
      .replaceAll(_spaces, ' ')
      .trim();
  final segments = _variant.allMatches(cleaned).toList();
  if (segments.isEmpty) return cleaned;
  final wanted = restaurant.toUpperCase();
  for (final segment in segments) {
    if (_codes(segment.group(2)!).contains(wanted)) {
      return segment.group(1)!.trim();
    }
  }
  return segments.first.group(1)!.trim();
}

Iterable<String> _codes(String list) => list
    .split(_codeSeparator)
    .map((c) => c.trim().toUpperCase())
    .where((c) => c.isNotEmpty && c != 'E');

bool _isRestaurantList(String list) {
  final codes = _codes(list).toList();
  return codes.isNotEmpty && codes.every(_restaurantCodes.contains);
}

const _restaurantCodes = {
  'RU', 'RA', 'RS', 'HC', 'CAISM', 'COTUCA', 'FOP', 'CPQBA', 'HEMOCENTRO', //
};

/// The visible text of [html], one trimmed, non-empty line per block.
List<String> htmlToLines(String html) {
  var text = html
      .replaceAll(_scriptOrStyle, ' ')
      .replaceAll(_lineBreak, '\n')
      .replaceAll(_blockEnd, '\n')
      .replaceAll(_blockStart, '\n')
      .replaceAll(_anyTag, ' ');
  text = decodeHtmlEntities(text);
  return [
    for (final line in text.split('\n'))
      if (line.replaceAll(_spaces, ' ').trim() case final t when t.isNotEmpty)
        t,
  ];
}

String decodeHtmlEntities(String text) =>
    text.replaceAllMapped(_entity, (m) {
      final body = m.group(1)!;
      if (body.startsWith('#x') || body.startsWith('#X')) {
        final code = int.tryParse(body.substring(2), radix: 16);
        return code == null ? m.group(0)! : String.fromCharCode(code);
      }
      if (body.startsWith('#')) {
        final code = int.tryParse(body.substring(1));
        return code == null ? m.group(0)! : String.fromCharCode(code);
      }
      return _namedEntities[body] ?? m.group(0)!;
    });

RuMealKind _kindOf(String word, {required bool vegan}) {
  final w = word.toLowerCase();
  if (w.startsWith('caf')) return RuMealKind.breakfast;
  if (w.startsWith('almo')) {
    return vegan ? RuMealKind.veganLunch : RuMealKind.lunch;
  }
  return vegan ? RuMealKind.veganDinner : RuMealKind.dinner;
}

final _heading = RegExp(
  r'^(café da manhã|almoço|jantar)( vegano)?$',
  caseSensitive: false,
  unicode: true,
);
final _noteSentence = RegExp(
  r'^(cont[ée]m\b|pode conter|n[ãa]o cont[ée]m|todos os dias|as refeiç|'
  r'o cardápio|o atendimento|aten[çc][ãa]o)',
  caseSensitive: false,
  unicode: true,
);
// The queue cameras and links that follow the last menu on the page.
final _pageEnd = RegExp(r'^acompanhe agora', caseSensitive: false);
final _notes = RegExp(
  r'observaç(ões|oes)\s*:',
  caseSensitive: false,
  unicode: true,
);
final _variant = RegExp(r'([^()|/;]+?)\s*\(([^)]*)\)\s*[|/;]?\s*');
final _parenthetical = RegExp(r'\(([^)]*)\)');
final _codeSeparator = RegExp(r'[\s,/\-]+');

final _scriptOrStyle = RegExp(
  r'<(script|style)\b[^>]*>[\s\S]*?</\1\s*>',
  caseSensitive: false,
);
final _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);
final _blockEnd = RegExp(
  r'</(p|div|li|ul|ol|h[1-6]|tr|td|th|table|section|article|header|footer|'
  r'main|nav|hr)\s*>',
  caseSensitive: false,
);
final _blockStart = RegExp(
  r'<(p|div|li|h[1-6]|tr|hr)\b[^>]*>',
  caseSensitive: false,
);
final _anyTag = RegExp(r'<[^>]*>');
final _spaces = RegExp(r'[\s ]+');
final _entity = RegExp(r'&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);');

const _namedEntities = {
  'nbsp': ' ', 'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', //
  'apos': "'", 'ordm': 'º', 'ordf': 'ª', 'deg': '°', 'ndash': '–', //
  'mdash': '—', 'hellip': '…', //
  'aacute': 'á', 'Aacute': 'Á', 'agrave': 'à', 'Agrave': 'À', //
  'acirc': 'â', 'Acirc': 'Â', 'atilde': 'ã', 'Atilde': 'Ã', //
  'eacute': 'é', 'Eacute': 'É', 'ecirc': 'ê', 'Ecirc': 'Ê', //
  'iacute': 'í', 'Iacute': 'Í', 'oacute': 'ó', 'Oacute': 'Ó', //
  'ocirc': 'ô', 'Ocirc': 'Ô', 'otilde': 'õ', 'Otilde': 'Õ', //
  'uacute': 'ú', 'Uacute': 'Ú', 'uuml': 'ü', 'Uuml': 'Ü', //
  'ccedil': 'ç', 'Ccedil': 'Ç',
};
