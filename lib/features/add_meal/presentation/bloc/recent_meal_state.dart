part of 'recent_meal_bloc.dart';

abstract class RecentMealState extends Equatable {
  const RecentMealState();
}

class RecentMealInitial extends RecentMealState {
  @override
  List<Object> get props => [];
}

class RecentMealLoadingState extends RecentMealState {
  @override
  List<Object?> get props => [];
}

class RecentMealLoadedState extends RecentMealState {
  final List<MealEntity> recentMeals;

  /// The intakes behind [recentMeals], same order — what was logged and how
  /// much, so a past food can be added again with the same amount.
  final List<IntakeEntity> recentIntakes;
  final bool usesImperialUnits;

  const RecentMealLoadedState({
    required this.recentMeals,
    this.recentIntakes = const [],
    this.usesImperialUnits = false,
  });

  @override
  List<Object?> get props => [recentMeals, recentIntakes, usesImperialUnits];
}

class RecentMealFailedState extends RecentMealState {
  @override
  List<Object?> get props => [];
}
