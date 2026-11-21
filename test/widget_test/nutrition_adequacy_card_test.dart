import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_adequacy_calc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/nutrition_adequacy_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../helpers/test_l10n.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [S.delegate],
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('shows energy and protein per kg against the minimum',
      (tester) async {
    final a = NutritionAdequacyCalc.evaluate(
      kcalIntake: 2110,
      kcalGoal: 2100,
      carbsG: 250,
      fatG: 70,
      proteinG: 120,
      weightKg: 90,
    );
    await tester.pumpWidget(
      _app(NutritionAdequacyCard(adequacy: a, kcalIntake: 2110, kcalGoal: 2100)),
    );
    expect(find.text('1.3 g/kg protein (min 1.6)'), findsOneWidget);
    expect(find.text('2110 of 2100 kcal'), findsOneWidget);
  });

  testWidgets('an empty day asks for a meal instead of showing zeros',
      (tester) async {
    final a = NutritionAdequacyCalc.evaluate(
      kcalIntake: 0,
      kcalGoal: 2100,
      carbsG: 0,
      fatG: 0,
      proteinG: 0,
      weightKg: 90,
    );
    await tester.pumpWidget(
      _app(NutritionAdequacyCard(adequacy: a, kcalIntake: 0, kcalGoal: 2100)),
    );
    expect(find.text(l10nEn.adequacyNoData), findsOneWidget);
  });
}
