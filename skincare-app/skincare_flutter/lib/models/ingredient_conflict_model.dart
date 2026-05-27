class IngredientConflict {
  final String ingredientA;
  final String ingredientB;
  final String severityLevel; // "High" | "Medium"
  final String warningMessage;

  IngredientConflict({
    required this.ingredientA,
    required this.ingredientB,
    required this.severityLevel,
    required this.warningMessage,
  });

  factory IngredientConflict.fromJson(Map<String, dynamic> json) {
    return IngredientConflict(
      ingredientA: json['ingredient_a'] as String,
      ingredientB: json['ingredient_b'] as String,
      severityLevel: json['severity_level'] as String,
      warningMessage: json['warning_message'] as String,
    );
  }
}