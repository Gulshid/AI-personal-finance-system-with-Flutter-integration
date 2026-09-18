/// Typed models mirroring the FastAPI response schemas in api/main.py.
/// Keeping these explicit (instead of passing raw Map<String, dynamic>
/// around) means typos and shape mismatches show up as compile errors
/// instead of runtime crashes deep in a widget.

class ClusterProfile {
  final int userId;
  final int cluster;
  final double monthlySpend;
  final Map<String, double> spendMix;

  const ClusterProfile({
    required this.userId,
    required this.cluster,
    required this.monthlySpend,
    required this.spendMix,
  });

  factory ClusterProfile.fromJson(Map<String, dynamic> json) {
    final mix = Map<String, dynamic>.from(json['spend_mix'] as Map);
    return ClusterProfile(
      userId: json['user_id'] as int,
      cluster: json['cluster'] as int,
      monthlySpend: (json['monthly_spend'] as num).toDouble(),
      spendMix: mix.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

class ForecastResult {
  final int userId;
  final Map<String, double> forecastNextMonth;

  const ForecastResult({required this.userId, required this.forecastNextMonth});

  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json['forecast_next_month'] as Map);
    return ForecastResult(
      userId: json['user_id'] as int,
      forecastNextMonth: map.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  double get total => forecastNextMonth.values.fold(0.0, (a, b) => a + b);
}

class RecommendationItem {
  final String type;
  final String category;
  final String message;

  const RecommendationItem({
    required this.type,
    required this.category,
    required this.message,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      type: (json['type'] ?? 'tip').toString(),
      category: (json['category'] ?? 'General').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class CategoryPrediction {
  final String predictedCategory;
  final double confidence;

  const CategoryPrediction({required this.predictedCategory, required this.confidence});

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    return CategoryPrediction(
      predictedCategory: json['predicted_category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class AnomalyResult {
  final bool isAnomaly;
  final double anomalyScore;
  final double? userTypicalAmount;
  final double? deviationStd;

  const AnomalyResult({
    required this.isAnomaly,
    required this.anomalyScore,
    this.userTypicalAmount,
    this.deviationStd,
  });

  factory AnomalyResult.fromJson(Map<String, dynamic> json) {
    return AnomalyResult(
      isAnomaly: json['is_anomaly'] as bool,
      anomalyScore: (json['anomaly_score'] as num).toDouble(),
      userTypicalAmount: (json['user_typical_amount'] as num?)?.toDouble(),
      deviationStd: (json['deviation_std'] as num?)?.toDouble(),
    );
  }
}
