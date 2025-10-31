class PredictionNutrition {
  final int? id;
  final String? filename;
  final String? label;
  final DateTime createdAt;
  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;
  final String takaran;
  final String? imageUrl;
  final String waktuMakan;

  PredictionNutrition({
    this.id,
    required this.filename,
    required this.label,
    required this.createdAt,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbohydrates,
    required this.takaran,
    required this.waktuMakan,
    this.imageUrl,
  });

  factory PredictionNutrition.fromJson(Map<String, dynamic> json) {
    return PredictionNutrition(
      id: json['id'] as int?,
      filename: json['filename']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      foodName: json['foodName'] ?? json['food_name'] ?? 'Tidak Diketahui',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      takaran: json['takaran']?.toString() ?? '-',
      waktuMakan: json['waktuMakan']?.toString() ?? '-',
      imageUrl: json['image_url']?.toString(),
    );
  }

  // get waktuMakan => null;
}
