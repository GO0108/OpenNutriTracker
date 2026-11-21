import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/usecase/get_today_steps_usecase.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// BR fork: today's steps from Samsung Health (via Health Connect), an
/// estimate of their energy and progress to [GetTodayStepsUsecase.dailyGoal].
///
/// Loads itself and reloads whenever the app comes back to the foreground,
/// so a walk shows up without touching the home bloc. Hidden entirely while
/// Health Connect sync is off.
class StepsCard extends StatefulWidget {
  final double weightKg;
  final Future<TodaySteps?> Function()? load;
  final Future<void> Function()? requestAccess;

  const StepsCard({
    super.key,
    required this.weightKg,
    this.load,
    this.requestAccess,
  });

  @override
  State<StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends State<StepsCard> with WidgetsBindingObserver {
  TodaySteps? _today;

  /// Unregistered in widget tests that pump the home page without it: no
  /// card rather than a locator error.
  Future<TodaySteps?> _load() async {
    final load = widget.load;
    if (load != null) return load();
    if (!locator.isRegistered<GetTodayStepsUsecase>()) return null;
    return locator<GetTodayStepsUsecase>().today();
  }

  Future<void> _refresh() async {
    final today = await _load();
    if (mounted) setState(() => _today = today);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _allow() async {
    await (widget.requestAccess ??
        locator<GetTodayStepsUsecase>().requestAccess)();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    if (today == null) return const SizedBox.shrink();

    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final steps = today.steps;

    return Card(
      key: const ValueKey('home-steps-card'),
      margin: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk_rounded, color: scheme.primary),
                const SizedBox(width: Dimens.spacing8),
                Text(s.stepsTitle, style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: Dimens.spacing8),
            if (steps == null) ...[
              Text(s.stepsConnect, style: textTheme.bodyMedium),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('home-steps-allow'),
                  onPressed: _allow,
                  child: Text(s.stepsAllow),
                ),
              ),
            ] else ...[
              Text(
                s.stepsCount(
                  number.format(steps),
                  number.format(
                    GetTodayStepsUsecase.estimateKcal(
                      steps,
                      widget.weightKg,
                    ).round(),
                  ),
                ),
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: Dimens.spacing8),
              LinearProgressIndicator(
                value: (steps / GetTodayStepsUsecase.dailyGoal).clamp(0, 1),
              ),
              const SizedBox(height: Dimens.spacing4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      s.stepsNote,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    s.stepsGoal(number.format(GetTodayStepsUsecase.dailyGoal)),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
