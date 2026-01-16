import 'package:equatable/equatable.dart';

/// Événements pour le BLoC de prédiction
abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

/// Événement: Démarrer une nouvelle prédiction
class StartPredictionEvent extends PredictionEvent {
  const StartPredictionEvent();
}

/// Événement: Soumettre les données pour prédiction
class SubmitPredictionEvent extends PredictionEvent {
  final int userId;
  final Map<String, int> symptoms;
  final String age;
  final String gender;
  final double humidity;
  final double temperature;
  final double pm25;
  final double respiratoryRate;

  const SubmitPredictionEvent({
    required this.userId,
    required this.symptoms,
    required this.age,
    required this.gender,
    required this.humidity,
    required this.temperature,
    required this.pm25,
    required this.respiratoryRate,
  });

  @override
  List<Object?> get props => [
        userId,
        symptoms,
        age,
        gender,
        humidity,
        temperature,
        pm25,
        respiratoryRate,
      ];
}

/// Événement: Charger l'historique des prédictions
class LoadPredictionHistoryEvent extends PredictionEvent {
  final int userId;

  const LoadPredictionHistoryEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Événement: Charger les statistiques
class LoadPredictionStatsEvent extends PredictionEvent {
  final int userId;
  final int days;

  const LoadPredictionStatsEvent(this.userId, {this.days = 30});

  @override
  List<Object?> get props => [userId, days];
}
