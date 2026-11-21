import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';

/// Today's steps, as the home card shows them.
class TodaySteps {
  /// Null when the health store would not say — usually the steps grant is
  /// missing, which the card offers to fix.
  final int? steps;

  const TodaySteps(this.steps);
}

/// BR fork: steps from Samsung Health, through Health Connect.
///
/// Rides on the workout import's switch like the weight import: with Health
/// Connect sync off there is no card at all.
class GetTodayStepsUsecase {
  /// A daily target the card measures against. The common 8,000 rather than
  /// the folklore 10,000: most of the mortality benefit in the step-count
  /// cohorts is reached by 7,000–8,000.
  static const dailyGoal = 8000;

  /// Gross energy of walking per kg of body weight per step — about 0.5 kcal
  /// per kg per km at roughly 1,300 steps/km. An estimate for the card, not
  /// a figure that enters the day's budget: the profile's activity level
  /// already counts everyday walking, so adding steps would count it twice.
  static const kcalPerKgPerStep = 0.0004;

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static final _log = Logger('GetTodayStepsUsecase');

  final HealthImportRepository _health;
  final GetConfigUsecase _getConfig;

  GetTodayStepsUsecase(this._health, this._getConfig);

  /// Null when the feature is off: sync disabled or no health store.
  Future<TodaySteps?> today() async {
    try {
      final config = await _getConfig.getConfig();
      if (!config.healthImportEnabled) return null;
      if (!await _health.isAvailable()) return null;
      final now = clock();
      final midnight = DateTime(now.year, now.month, now.day);
      return TodaySteps(await _health.getSteps(from: midnight, to: now));
    } catch (e) {
      _log.info('Steps unavailable: $e');
      return const TodaySteps(null);
    }
  }

  /// Opens the Health Connect grant sheet. Never throws.
  Future<void> requestAccess() async {
    try {
      await _health.requestPermissions();
    } catch (e) {
      _log.info('Steps permission request failed: $e');
    }
  }

  static double estimateKcal(int steps, double weightKg) =>
      steps * weightKg * kcalPerKgPerStep;
}
