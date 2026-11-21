import 'package:equatable/equatable.dart';

/// Which service of the Unicamp university restaurants a menu belongs to.
enum RuMealKind { breakfast, lunch, veganLunch, dinner, veganDinner }

/// One service from the Prefeitura da Unicamp menu page, as published:
/// "Almoço" with its main dish, the rest of the plate, and the notes.
class RuMeal extends Equatable {
  final RuMealKind kind;

  /// The page's own heading, e.g. "Almoço Vegano" — shown as-is.
  final String title;

  /// The protein of the day, or null when the page lists none (the base
  /// "ARROZ E FEIJÃO" line came first).
  final String? mainDish;

  /// The other lines in page order, still carrying any per-restaurant
  /// annotation such as "LARANJA (RU, RA e HC) / MAÇÃ (RS)".
  final List<String> items;

  /// Allergen and service notes after "Observações:".
  final String? notes;

  const RuMeal({
    required this.kind,
    required this.title,
    required this.mainDish,
    required this.items,
    required this.notes,
  });

  @override
  List<Object?> get props => [kind, title, mainDish, items, notes];
}
