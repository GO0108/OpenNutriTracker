# TACO data

`food.csv`, `nutrients.csv` and `fatty-acids.csv` are copied unchanged from
[raulfdm/taco-api](https://github.com/raulfdm/taco-api) (`references/csv/`,
MIT licence, commit of 2025-02-10), which transcribes:

> Tabela Brasileira de Composição de Alimentos – TACO, 4ª ed. rev. e ampl.
> NEPA – UNICAMP, Campinas, 2011. "É permitida a reprodução parcial ou total
> desta obra, desde que citada a fonte."

Household measures in `../taco_curation.json` come from IBGE, *Pesquisa de
Orçamentos Familiares 2008–2009: Tabela de Medidas Referidas para os
Alimentos Consumidos no Brasil* (2011), "unidade média" / "cheia" rows.

Regenerate the app asset after editing any of these files:

```sh
dart run tool/taco/convert_taco.dart
```
