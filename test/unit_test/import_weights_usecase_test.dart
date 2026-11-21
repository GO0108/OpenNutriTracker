import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_weights_usecase.dart';

import '../helpers/recording_add_weight_log_usecase.dart';

class _FakeHealthRepo extends Fake implements HealthImportRepository {
  final List<ExternalWeight> weights;
  final bool throws;
  int weightReads = 0;

  _FakeHealthRepo({this.weights = const [], this.throws = false});

  @override
  Future<List<ExternalWeight>> getWeights({
    required DateTime from,
    required DateTime to,
  }) async {
    weightReads++;
    if (throws) throw StateError('Health Connect said no');
    return weights;
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

class _FakeGetWeightLog extends Fake implements GetWeightLogUsecase {
  final List<WeightLogEntity> entries;

  _FakeGetWeightLog(this.entries);

  @override
  Future<List<WeightLogEntity>> getEntriesInRange(
    DateTime from,
    DateTime to,
  ) async => entries;
}

void main() {
  setUp(() => ImportWeightsUsecase.clock = () => DateTime(2026, 11, 20, 22));
  tearDown(() => ImportWeightsUsecase.clock = DateTime.now);

  ({ImportWeightsUsecase usecase, RecordingAddWeightLogUsecase added}) build({
    required _FakeHealthRepo health,
    bool enabled = true,
    List<WeightLogEntity> existing = const [],
  }) {
    final added = RecordingAddWeightLogUsecase();
    return (
      usecase: ImportWeightsUsecase(
        health,
        _FakeGetConfig(enabled),
        _FakeGetWeightLog(existing),
        added,
      ),
      added: added,
    );
  }

  test('disabled import reads nothing', () async {
    final health = _FakeHealthRepo(
      weights: [ExternalWeight(time: DateTime(2026, 11, 20, 7), kg: 81)],
    );
    final (:usecase, :added) = build(health: health, enabled: false);
    expect(await usecase.importIfDue(), 0);
    expect(health.weightReads, 0);
    expect(added.entries, isEmpty);
  });

  test('two readings on one day keep the latest', () async {
    final (:usecase, :added) = build(
      health: _FakeHealthRepo(
        weights: [
          ExternalWeight(time: DateTime(2026, 11, 20, 7), kg: 81.2),
          ExternalWeight(time: DateTime(2026, 11, 20, 21), kg: 80.9),
        ],
      ),
    );
    expect(await usecase.importIfDue(), 1);
    expect(added.entries.single.weightKg, 80.9);
    expect(added.entries.single.note, ImportWeightsUsecase.note);
  });

  test('a day already weighed in the app is not touched', () async {
    final (:usecase, :added) = build(
      existing: [WeightLogEntity(date: DateTime(2026, 11, 19, 8), weightKg: 82)],
      health: _FakeHealthRepo(
        weights: [
          ExternalWeight(time: DateTime(2026, 11, 19, 9), kg: 81.5),
          ExternalWeight(time: DateTime(2026, 11, 20, 9), kg: 81.0),
        ],
      ),
    );
    expect(await usecase.importIfDue(), 1);
    expect(added.entries.single.date, DateTime(2026, 11, 20, 9));
  });

  test('second call within 15 minutes does not read again', () async {
    final health = _FakeHealthRepo();
    final (:usecase, added: _) = build(health: health);
    await usecase.importIfDue();
    await usecase.importIfDue();
    expect(health.weightReads, 1);
  });

  test('a failing health read returns 0 instead of throwing', () async {
    final (:usecase, added: _) = build(health: _FakeHealthRepo(throws: true));
    expect(await usecase.importIfDue(), 0);
  });
}
