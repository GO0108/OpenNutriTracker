import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';

const ruLunch = RuMeal(
  kind: RuMealKind.lunch,
  title: 'Almoço',
  mainDish: 'CUBOS DE FRANGO AO MOLHO SHOYU',
  items: [
    'ARROZ E FEIJÃO',
    'CREME DE MILHO',
    'SALADA DE BETERRABA RALADA',
    'LARANJA (RU, RA e HC) / MAÇÃ (RS)',
    'REFRESCO DE UVA',
  ],
  notes: null,
);

/// Markup in the spirit of the Prefeitura page: headings, one line per
/// item, notes after "Observações:", and page chrome before the first
/// heading. The real page's markup is checked separately when a saved copy
/// is present (see ru_menu_parser_test.dart).
const ruSyntheticPage = '''
<html><head><style>.x{color:red}</style></head><body>
<div>Prefeitura da Unicamp</div>
<h2>Almoço</h2><div>CUBOS DE FRANGO AO MOLHO SHOYU</div>
<ul><li>ARROZ E FEIJÃO</li><li>CREME DE MILHO</li>
<li>SALADA DE BETERRABA RALADA</li>
<li>LARANJA (RU, RA e HC) / MAÇÃ (RS)</li><li>REFRESCO DE UVA</li></ul>
<p>Observações: CONTÉM GLÚTEN NO PÃO FRANCÊS</p>
<h2>Almoço Vegano</h2><div>ENSOPADO DE ERVILHAS COM BRÓCOLIS</div>
<ul><li>ARROZ INTEGRAL E FEIJÃO</li></ul>
<h2>Jantar</h2><ul><li>ARROZ E FEIJÃO</li><li>ABOBRINHA REFOGADA</li></ul>
</body></html>''';
