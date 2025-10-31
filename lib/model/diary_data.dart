import '../model/PredictionNutrition.dart';
import '../model/UserCalories.dart';


class DiaryData {
  final UserCalories userCalories;
  final List<PredictionNutrition> history;
  final double consumedCalories;
  final double consumedCarbs;
  final double consumedProtein;
  final double consumedFat;

  DiaryData({
    required this.userCalories,
    required this.history,
    required this.consumedCalories,
    required this.consumedCarbs,
    required this.consumedProtein,
    required this.consumedFat,
  });
}
