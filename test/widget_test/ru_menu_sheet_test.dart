import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/ru_menu/presentation/ru_menu_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../fixture/ru_fixtures.dart';
import '../helpers/test_l10n.dart';

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: const [S.delegate],
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: home),
);

void main() {
  testWidgets('tapping a meal returns its log text', (tester) async {
    String? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showModalBottomSheet<String>(
              context: context,
              builder: (_) => RuMenuSheet(load: () async => [ruLunch]),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Almoço'));
    await tester.pumpAndSettle();
    expect(result, startsWith('120 g peito de frango cozido'));
    expect(result, contains('1 laranja'));
  });

  testWidgets('choosing RS changes the fruit', (tester) async {
    String? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (_) => RuMenuSheet(load: () async => [ruLunch]),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Almoço'));
    await tester.pumpAndSettle();
    expect(result, contains('1 maçã'));
  });

  testWidgets('empty menu shows the unavailable message', (tester) async {
    await tester.pumpWidget(_app(RuMenuSheet(load: () async => const [])));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.ruMenuUnavailable), findsOneWidget);
  });
}
