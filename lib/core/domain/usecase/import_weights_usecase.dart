import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';

/// Brings body weight from the platform health store into the weight log —
/// on a Samsung phone, what Samsung Health shares with Health Connect.
///
/// Rides on the workout import's switch (`healthImportEnabled`), and keeps
/// the weight log's one-reading-per-day shape: of several readings on one
/// day the latest wins, and a day the user already weighed in the app is
/// left alone, whatever the health store says about it.
class ImportWeightsUsecase {
  static const lookback = Duration(days: 30);
  static const minimumInterval = Duration(minutes: 15);
  static const note = 'Health Connect';

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static final _log = Logger('ImportWeightsUsecase');

  final HealthImportRepository _health;
  final GetConfigUsecase _getConfig;
  final GetWeightLogUsecase _getWeightLog;
  final AddWeightLogUsecase _addWeightLog;

  DateTime? _lastRunAt;

  ImportWeightsUsecase(
    this._health,
    this._getConfig,
    this._getWeightLog,
    this._addWeightLog,
  );

  /// Imports what is new and returns how many days it added. Never throws.
  Future<int> importIfDue() async {
    try {
      final config = await _getConfig.getConfig();
      if (!config.healthImportEnabled) return 0;
      final now = clock();
      final last = _lastRunAt;
      if (last != null && now.difference(last) < minimumInterval) return 0;
      _lastRunAt = now;

      final from = now.subtract(lookback);
      final readings = await _health.getWeights(from: from, to: now);
      if (readings.isEmpty) return 0;

      final existing = await _getWeightLog.getEntriesInRange(from, now);
      final loggedDays = {
        for (final entry in existing) _day(entry.filedDay ?? entry.date),
      };

      final latestByDay = <DateTime, ExternalWeight>{};
      for (final reading in readings) {
        final day = _day(reading.time);
        final current = latestByDay[day];
        if (current == null || reading.time.isAfter(current.time)) {
          latestByDay[day] = reading;
        }
      }

      final days = latestByDay.keys.toList()..sort();
      var added = 0;
      for (final day in days) {
        if (loggedDays.contains(day)) continue;
        final reading = latestByDay[day]!;
        await _addWeightLog.addEntry(
          WeightLogEntity(date: reading.time, weightKg: reading.kg, note: note),
        );
        added++;
      }
      return added;
    } catch (e, stackTrace) {
      _log.warning('Weight import failed', e, stackTrace);
      return 0;
    }
  }

  static DateTime _day(DateTime time) {
    final local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
