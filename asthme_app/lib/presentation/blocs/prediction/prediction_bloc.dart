import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/data/repositories/prediction_repository.dart';
import 'package:asthme_app/data/models/sensor_data.dart';
import 'prediction_event.dart';
import 'prediction_state.dart';

/// BLoC pour gérer les prédictions d'asthme
class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final PredictionRepository _repository;

  PredictionBloc({PredictionRepository? repository})
      : _repository = repository ?? PredictionRepository(),
        super(const PredictionInitial()) {
    on<StartPredictionEvent>(_onStartPrediction);
    on<SubmitPredictionEvent>(_onSubmitPrediction);
    on<LoadPredictionHistoryEvent>(_onLoadHistory);
    on<LoadPredictionStatsEvent>(_onLoadStats);
  }

  /// Gérer le début d'une nouvelle prédiction
  void _onStartPrediction(
    StartPredictionEvent event,
    Emitter<PredictionState> emit,
  ) {
    emit(const PredictionInitial());
  }

  /// Gérer la soumission des données pour prédiction
  Future<void> _onSubmitPrediction(
    SubmitPredictionEvent event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(const PredictionLoading());

      // Créer l'objet SensorData
      final sensorData = SensorData(
        humidity: event.humidity,
        temperature: event.temperature,
        pm25: event.pm25,
        respiratoryRate: event.respiratoryRate,
        timestamp: DateTime.now(),
      );

      // Appeler le repository pour la prédiction
      final result = await _repository.predictAsthmaRisk(
        userId: event.userId,
        symptoms: event.symptoms,
        age: event.age,
        gender: event.gender,
        sensorData: sensorData,
      );

      if (result == null || result['success'] != true) {
        emit(const PredictionError(
          'Impossible d\'obtenir une prédiction. Vérifiez votre connexion.',
        ));
        return;
      }

      // Convertir les probabilités en Map<String, double>
      final probabilities = <String, double>{};
      if (result['probabilities'] != null) {
        (result['probabilities'] as Map<String, dynamic>).forEach((key, value) {
          probabilities[key] = (value as num).toDouble();
        });
      }

      // Convertir les recommandations en List<String>
      final recommendations = <String>[];
      if (result['recommendations'] != null) {
        recommendations.addAll(
          (result['recommendations'] as List).map((e) => e.toString()),
        );
      }

      emit(PredictionSuccess(
        riskLevel: result['risk_level'] as int,
        riskLabel: result['risk_label'] as String,
        riskScore: (result['risk_score'] as num).toDouble(),
        probabilities: probabilities,
        recommendations: recommendations,
      ));
    } catch (e) {
      emit(PredictionError('Erreur lors de la prédiction: $e'));
    }
  }

  /// Gérer le chargement de l'historique
  Future<void> _onLoadHistory(
    LoadPredictionHistoryEvent event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(const PredictionLoading());

      final history = await _repository.getPredictionHistory(event.userId);

      emit(PredictionHistoryLoaded(history));
    } catch (e) {
      emit(PredictionError('Erreur lors du chargement de l\'historique: $e'));
    }
  }

  /// Gérer le chargement des statistiques
  Future<void> _onLoadStats(
    LoadPredictionStatsEvent event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(const PredictionLoading());

      final stats = await _repository.getRiskStats(
        event.userId,
        days: event.days,
      );

      emit(PredictionStatsLoaded(stats));
    } catch (e) {
      emit(PredictionError('Erreur lors du chargement des stats: $e'));
    }
  }
}
