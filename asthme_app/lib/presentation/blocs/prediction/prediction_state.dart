import 'package:equatable/equatable.dart';

/// États du BLoC de prédiction
abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object?> get props => [];
}

/// État initial
class PredictionInitial extends PredictionState {
  const PredictionInitial();
}

/// État de chargement
class PredictionLoading extends PredictionState {
  const PredictionLoading();
}

/// État de succès avec résultat de prédiction
class PredictionSuccess extends PredictionState {
  final int riskLevel;
  final String riskLabel;
  final double riskScore;
  final Map<String, double> probabilities;
  final List<String> recommendations;

  const PredictionSuccess({
    required this.riskLevel,
    required this.riskLabel,
    required this.riskScore,
    required this.probabilities,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [
        riskLevel,
        riskLabel,
        riskScore,
        probabilities,
        recommendations,
      ];

  /// Obtenir la couleur associée au niveau de risque
  String get riskColor {
    switch (riskLevel) {
      case 1:
        return 'green'; // Faible
      case 2:
        return 'orange'; // Modéré
      case 3:
        return 'red'; // Élevé
      default:
        return 'grey';
    }
  }

  /// Obtenir l'emoji associé au niveau de risque
  String get riskEmoji {
    switch (riskLevel) {
      case 1:
        return '✅'; // Faible
      case 2:
        return '⚠️'; // Modéré
      case 3:
        return '🚨'; // Élevé
      default:
        return '❓';
    }
  }
}

/// État d'erreur
class PredictionError extends PredictionState {
  final String message;

  const PredictionError(this.message);

  @override
  List<Object?> get props => [message];
}

/// État avec historique chargé
class PredictionHistoryLoaded extends PredictionState {
  final List<Map<String, dynamic>> history;

  const PredictionHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

/// État avec statistiques chargées
class PredictionStatsLoaded extends PredictionState {
  final Map<String, int> stats;

  const PredictionStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}
