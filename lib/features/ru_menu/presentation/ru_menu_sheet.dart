import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/ru_menu/data/ru_menu_data_source.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_meal.dart';
import 'package:opennutritracker/features/ru_menu/domain/ru_plate_text.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Opens the day's Unicamp restaurant menu and returns the chosen tray as
/// log text for the review screen, or null when dismissed.
Future<String?> showRuMenuSheet(
  BuildContext context, {
  required DateTime day,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => RuMenuSheet(load: () => locator<RuMenuDataSource>().fetch(day)),
);

class RuMenuSheet extends StatefulWidget {
  final Future<List<RuMeal>> Function() load;

  const RuMenuSheet({super.key, required this.load});

  @override
  State<RuMenuSheet> createState() => _RuMenuSheetState();
}

class _RuMenuSheetState extends State<RuMenuSheet> {
  static const _restaurants = ['RU', 'RA', 'RS'];

  late final Future<List<RuMeal>> _meals = widget.load();
  String _restaurant = _restaurants.first;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.spacing16,
          0,
          Dimens.spacing16,
          Dimens.spacing16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.ruMenuTile, style: textTheme.titleLarge),
            const SizedBox(height: Dimens.spacing12),
            Semantics(
              identifier: 'ru-menu-restaurant',
              child: SegmentedButton<String>(
                segments: [
                  for (final r in _restaurants)
                    ButtonSegment(value: r, label: Text(r)),
                ],
                selected: {_restaurant},
                onSelectionChanged: (selection) =>
                    setState(() => _restaurant = selection.first),
              ),
            ),
            const SizedBox(height: Dimens.spacing12),
            FutureBuilder<List<RuMeal>>(
              future: _meals,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(Dimens.spacing24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final meals = snapshot.data ?? const <RuMeal>[];
                if (meals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(Dimens.spacing24),
                    child: Text(
                      s.ruMenuUnavailable,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Semantics(
                  identifier: 'ru-menu-meals',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final meal in meals)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(meal.title),
                          subtitle: Text(
                            meal.mainDish ?? meal.items.first,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(
                            ruMealToLogText(meal, restaurant: _restaurant),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
