import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_adequacy_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Today's intake against the energy goal, the healthy share of energy from
/// each macronutrient, and protein per kg of body weight.
class NutritionAdequacyCard extends StatelessWidget {
  final NutritionAdequacy adequacy;
  final double kcalIntake;
  final double kcalGoal;

  const NutritionAdequacyCard({
    super.key,
    required this.adequacy,
    required this.kcalIntake,
    required this.kcalGoal,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Color colorOf(AdequacyStatus status) => switch (status) {
      AdequacyStatus.ok => scheme.primary,
      AdequacyStatus.low || AdequacyStatus.high => scheme.error,
      AdequacyStatus.noData => scheme.onSurfaceVariant,
    };

    Widget line(String text, AdequacyStatus status) => Padding(
      padding: const EdgeInsets.only(top: Dimens.spacing4),
      child: Row(
        children: [
          Icon(
            status == AdequacyStatus.ok
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 18,
            color: colorOf(status),
          ),
          const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    String pct(double share) => (share * 100).round().toString();
    String macro(
      String name,
      double share,
      ({double min, double max}) r,
    ) => s.adequacyMacroShare(
      name,
      pct(share),
      pct(r.min),
      pct(r.max),
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.adequacyTitle, style: textTheme.titleMedium),
            if (!adequacy.hasData)
              Padding(
                padding: const EdgeInsets.only(top: Dimens.spacing4),
                child: Text(s.adequacyNoData, style: textTheme.bodyMedium),
              )
            else ...[
              line(
                s.adequacyKcal(
                  kcalIntake.round().toString(),
                  kcalGoal.round().toString(),
                ),
                adequacy.kcal,
              ),
              line(
                macro(
                  s.mealCarbsLabel,
                  adequacy.carbsPct,
                  NutritionAdequacyCalc.carbsRange,
                ),
                adequacy.carbs,
              ),
              line(
                macro(
                  s.mealFatLabel,
                  adequacy.fatPct,
                  NutritionAdequacyCalc.fatRange,
                ),
                adequacy.fat,
              ),
              line(
                macro(
                  s.mealProteinLabel,
                  adequacy.proteinPct,
                  NutritionAdequacyCalc.proteinRange,
                ),
                adequacy.protein,
              ),
              if (adequacy.proteinPerKg != AdequacyStatus.noData)
                line(
                  s.adequacyProteinPerKg(
                    adequacy.proteinGPerKg.toStringAsFixed(1),
                    NutritionAdequacyCalc.minProteinGPerKg.toString(),
                  ),
                  adequacy.proteinPerKg,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
