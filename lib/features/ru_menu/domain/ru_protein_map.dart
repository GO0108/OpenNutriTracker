/// The RU main dish, named the way the food table knows it.
///
/// The menu says "CARNE EM CUBOS AO MOLHO RÚSTICO" or "ISCAS DE FRANGO AO
/// SHOYO"; nothing in a food table is called that, and a search on the whole
/// phrase lands on whatever shares a word with it. This list maps the dish
/// to a plain name that is a curated TACO alias ("carne bovina cozida",
/// "peito de frango cozido"), so the protein — the part of the tray that
/// matters most for the calories — resolves to the right TACO row.
///
/// Deliberately simple: each rule is a few keywords that must all appear
/// (each keyword may list alternatives with "|"), checked in order, first
/// match wins. Specific rules come before general ones ("BISTECA" before
/// "SUÍNO", "EMPANADO" before plain "FRANGO"). Keywords are matched on the
/// upper-case dish without accents.
const ruProteinRules = <(List<String>, String)>[
  (['FEIJOADA'], 'feijoada'),
  (['ESTROGONOFE|STROGONOFF|STROGONOF', 'FRANGO'], 'estrogonofe de frango'),
  (['ESTROGONOFE|STROGONOFF|STROGONOF'], 'estrogonofe de carne'),
  // Vegan dishes keep their own name: TACO has no cooked soy protein.
  (['PTS|SOJA|PROTEINA TEXTURIZADA|GRAO DE BICO|LENTILHA|TOFU'], ''),
  (['BISTECA'], 'bisteca suína'),
  (['LINGUICA'], 'linguiça de porco'),
  (['PERNIL'], 'pernil suíno'),
  (['LOMBO'], 'lombo suíno'),
  (['COSTELA', 'SUIN|PORCO'], 'costela suína'),
  (['SUIN|PORCO'], 'carne suína'),
  (['COSTELA'], 'costela bovina'),
  (['FRANGO|SOBRECOXA|COXA', 'EMPANAD|MILANESA|NUGGET'], 'frango empanado'),
  (['SOBRECOXA'], 'sobrecoxa de frango'),
  (['COXA'], 'coxa de frango'),
  (['FRANGO', 'ASSAD'], 'frango assado'),
  (['FRANGO|GALINHA'], 'peito de frango cozido'),
  (['ALMONDEGA'], 'almôndegas de carne'),
  (['HAMBURGUER'], 'hambúrguer bovino'),
  (['QUIBE|KIBE'], 'quibe assado'),
  (['FIGADO'], 'fígado bovino'),
  (['CARNE', 'MOID'], 'carne moída'),
  (['BIFE|CARNE|BOVIN|ALCATRA|CONTRA', 'EMPANAD|MILANESA'], 'bife à milanesa'),
  (['BIFE|ALCATRA|CONTRA FILE|CONTRA-FILE|MAMINHA|PATINHO'], 'bife'),
  (
    ['CARNE|BOVIN|ACEM|MUSCULO|CUPIM|FRALDINHA|PICADINHO|GOULASH|LAGARTO'],
    'carne bovina cozida',
  ),
  (['SARDINHA'], 'sardinha assada'),
  (['ATUM'], 'atum'),
  (
    [
      'PEIXE|PESCADA|MERLUZA|TILAPIA|HADDOCK|POLACA|CACAO|SALMAO',
      'EMPANAD|FRIT|MILANESA',
    ],
    'peixe empanado',
  ),
  (
    ['PEIXE|PESCADA|MERLUZA|TILAPIA|HADDOCK|POLACA|CACAO|SALMAO'],
    'peixe assado',
  ),
  (['OMELETE|FRITADA'], 'omelete'),
  (['OVO'], 'ovo frito'),
];

/// The food-table name for [mainDish], or null to keep the dish's own name
/// (no rule matched, or a vegan dish).
String? ruProteinName(String mainDish) {
  final dish = _plain(mainDish);
  for (final (keywords, name) in ruProteinRules) {
    final matches = keywords.every(
      (keyword) => keyword.split('|').any(dish.contains),
    );
    if (matches) return name.isEmpty ? null : name;
  }
  return null;
}

String _plain(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toUpperCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

const _accents = {
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', //
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', //
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', //
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O', //
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', //
  'Ç': 'C',
};
