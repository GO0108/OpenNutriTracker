import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_today_steps_usecase.dart';
import 'package:opennutritracker/features/home/presentation/widgets/steps_card.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _FakeHealthRepo extends Fake implements HealthImportRepository {
  int? steps;
  bool available = true;
  bool throws = false;
  DateTime? from;
  DateTime? to;
  int permissionRequests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<int?> getSteps({required DateTime from, required DateTime to}) async {
    this.from = from;
    this.to = to;
    if (throws) throw StateError('rate limited');
    return steps;
  }

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    return true;
  }
}

class _FakeGetConfig extends Fake implements GetConfigUsecase {
  final bool enabled;

  _FakeGetConfig(this.enabled);

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    healthImportEnabled: enabled,
  );
}

void main() {
  setUp(
    () => GetTodayStepsUsecase.clock = () => DateTime(2026, 11, 21, 15, 30),
  );
  tearDown(() => GetTodayStepsUsecase.clock = DateTime.now);

  group('GetTodayStepsUsecase', () {
    test('reads from local midnight to now', () async {
      final health = _FakeHealthRepo()..steps = 6543;
      final today = await GetTodayStepsUsecase(
        health,
        _FakeGetConfig(true),
      ).today();
      expect(today?.steps, 6543);
      expect(health.from, DateTime(2026, 11, 21));
      expect(health.to, DateTime(2026, 11, 21, 15, 30));
    });

    test('no card while Health Connect sync is off', () async {
      final health = _FakeHealthRepo()..steps = 100;
      expect(
        await GetTodayStepsUsecase(health, _FakeGetConfig(false)).today(),
        isNull,
      );
      expect(health.from, isNull);
    });

    test('no card without a health store', () async {
      final health = _FakeHealthRepo()..available = false;
      expect(
        await GetTodayStepsUsecase(health, _FakeGetConfig(true)).today(),
        isNull,
      );
    });

    test('a missing grant or a failed read asks for access', () async {
      final missing = await GetTodayStepsUsecase(
        _FakeHealthRepo(),
        _FakeGetConfig(true),
      ).today();
      expect(missing, isNotNull);
      expect(missing!.steps, isNull);

      final failed = await GetTodayStepsUsecase(
        _FakeHealthRepo()..throws = true,
        _FakeGetConfig(true),
      ).today();
      expect(failed!.steps, isNull);
    });

    test('kcal estimate scales with steps and weight', () {
      expect(GetTodayStepsUsecase.estimateKcal(8000, 80), closeTo(256, 0.01));
      expect(GetTodayStepsUsecase.estimateKcal(0, 80), 0);
    });
  });

  group('StepsCard', () {
    Widget host(Widget child) => MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: child),
    );

    testWidgets('hidden when the feature is off', (tester) async {
      await tester.pumpWidget(
        host(StepsCard(weightKg: 80, load: () async => null)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-steps-card')), findsNothing);
    });

    testWidgets('shows steps and the estimate', (tester) async {
      await tester.pumpWidget(
        host(StepsCard(weightKg: 80, load: () async => const TodaySteps(8000))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-steps-card')), findsOneWidget);
      expect(find.textContaining('8.000 passos'), findsOneWidget);
      expect(find.textContaining('256 kcal'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('offers access when the grant is missing', (tester) async {
      var steps = const TodaySteps(null);
      var requests = 0;
      await tester.pumpWidget(
        host(
          StepsCard(
            weightKg: 80,
            load: () async => steps,
            requestAccess: () async {
              requests++;
              steps = const TodaySteps(1200);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-steps-allow')));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.textContaining('1.200 passos'), findsOneWidget);
    });
  });
}
