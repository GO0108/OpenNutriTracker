// Converts the vendored TACO CSVs plus the hand-curated aliases and
// household measures into `assets/taco/taco.json`, the file the app loads
// at start-up (`TacoFoodDataSource.loadFromAsset`).
//
// Run from the package root: `dart run tool/taco/convert_taco.dart`.
// `test/unit_test/taco_convert_test.dart` fails if the committed asset and
// this converter's output ever disagree.
import 'dart:convert';
import 'dart:io';

/// Nutrient columns kept from `nutrients.csv`, keyed by the CSV header and
/// mapped to the asset's key. Values are per 100 g of edible part.
const _nutrientColumns = <String, String>{
  'kcal': 'kcal',
  'protein': 'protein',
  'lipids': 'fat',
  'carbohydrates': 'carbs',
  'dietaryFiber': 'fiber',
  'cholesterol': 'cholesterol',
  'sodium': 'sodium',
  'potassium': 'potassium',
  'magnesium': 'magnesium',
  'calcium': 'calcium',
  'iron': 'iron',
  'zinc': 'zinc',
  'phosphorus': 'phosphorus',
  'rae': 'vitaminA',
  'vitaminC': 'vitaminC',
  'pyridoxine': 'vitaminB6',
  'niacin': 'niacin',
};

List<Map<String, Object?>> convertTaco({
  required String foodCsv,
  required String nutrientsCsv,
  required String fattyAcidsCsv,
  required String curationJson,
}) {
  final nutrients = _byFoodId(parseCsv(nutrientsCsv), 'foodId');
  final fattyAcids = _byFoodId(parseCsv(fattyAcidsCsv), 'foodId');
  final curation = (jsonDecode(curationJson) as Map).cast<String, Object?>();

  final foods = parseCsv(foodCsv);
  return [
    for (final food in foods)
      _record(
        food,
        nutrients[food['id']] ?? const {},
        fattyAcids[food['id']] ?? const {},
        (curation[food['id']] as Map?)?.cast<String, Object?>() ?? const {},
      ),
  ];
}

Map<String, Object?> _record(
  Map<String, String> food,
  Map<String, String> nutrients,
  Map<String, String> fattyAcids,
  Map<String, Object?> curation,
) {
  return {
    'id': int.parse(food['id']!.trim()),
    'name': food['name']!.trim(),
    'categoryId': int.parse(food['categoryId']!.trim()),
    for (final entry in _nutrientColumns.entries)
      entry.value: _number(nutrients[entry.key]),
    'saturatedFat': _number(fattyAcids['saturated']),
    'aliases': [
      for (final alias in (curation['aliases'] as List?) ?? const [])
        alias as String,
    ],
    'portions': [
      for (final portion in (curation['portions'] as List?) ?? const [])
        {
          'label': (portion as Map)['label'] as String,
          'en': portion['en'] as String,
          'g': (portion['g'] as num).toDouble(),
        },
    ],
  };
}

/// Null for a blank cell: TACO leaves a nutrient empty when it was not
/// measured, which is not the same as zero.
double? _number(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  return double.tryParse(text.replaceAll(',', '.'));
}

Map<String, Map<String, String>> _byFoodId(
  List<Map<String, String>> rows,
  String key,
) => {for (final row in rows) row[key]!.trim(): row};

/// Minimal RFC 4180 reader: quoted fields may contain commas and doubled
/// quotes. Enough for the TACO files, which quote names such as
/// `"Arroz, tipo 1, cozido"`.
List<Map<String, String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  final nonEmpty = rows.where((r) => r.any((f) => f.isNotEmpty)).toList();
  if (nonEmpty.isEmpty) return const [];
  final header = nonEmpty.first;
  return [
    for (final r in nonEmpty.skip(1))
      {
        for (var i = 0; i < header.length; i++)
          header[i]: i < r.length ? r[i] : '',
      },
  ];
}

void main() {
  String read(String path) => File('tool/taco/$path').readAsStringSync();
  final records = convertTaco(
    foodCsv: read('data/food.csv'),
    nutrientsCsv: read('data/nutrients.csv'),
    fattyAcidsCsv: read('data/fatty-acids.csv'),
    curationJson: read('taco_curation.json'),
  );
  final out = File('assets/taco/taco.json')..createSync(recursive: true);
  out.writeAsStringSync(jsonEncode(records));
  stdout.writeln('Wrote ${records.length} foods to ${out.path}');
}
