import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:asthme_app/core/constants/api_constants.dart';

/// Service de test pour vérifier la connexion à l'API Gemini
class ChatbotTestService {
  Future<void> testConnection() async {
    try {
      print('🔄 Test de connexion à l\'API Gemini...');
      print('🔑 Clé API (10 premiers caractères): ${ApiConstants.geminiApiKey.substring(0, 10)}...');
      print('📦 Modèle configuré: ${ApiConstants.geminiModel}\n');

      // Tester différents noms de modèles
      final modelNames = [
        ApiConstants.geminiModel, // Le modèle configuré
        'gemini-pro',
        'models/gemini-pro',
        'gemini-1.0-pro',
        'models/gemini-1.0-pro',
      ];

      bool foundWorkingModel = false;

      for (final modelName in modelNames) {
        if (foundWorkingModel) break;

        try {
          print('🧪 Test du modèle: $modelName');

          final model = GenerativeModel(
            model: modelName,
            apiKey: ApiConstants.geminiApiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7,
              maxOutputTokens: 100,
            ),
          );

          print('   ✓ Modèle initialisé');
          print('   📤 Envoi du message de test...');

          final response = await model.generateContent([
            Content.text('Bonjour, réponds simplement "OK" si tu me comprends.')
          ]).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout après 10 secondes'),
          );

          if (response.text != null && response.text!.isNotEmpty) {
            print('   ✅ SUCCÈS! Réponse reçue:');
            print('   "${response.text}"\n');
            print('🎉 Le modèle $modelName fonctionne parfaitement!\n');
            print('💡 Mettez à jour api_constants.dart avec:');
            print('   static const String geminiModel = \'$modelName\';');
            foundWorkingModel = true;
            return;
          }

        } catch (e) {
          print('   ❌ Échec: ${e.toString().split('\n')[0]}');
          if (e.toString().contains('API key')) {
            print('   ⚠️  Problème avec la clé API!');
          } else if (e.toString().contains('not found')) {
            print('   ℹ️  Modèle non disponible');
          } else if (e.toString().contains('quota') || e.toString().contains('limit')) {
            print('   ⚠️  Quota dépassé ou limite atteinte');
          }
          print('');
        }
      }

      if (!foundWorkingModel) {
        print('\n❌ AUCUN MODÈLE N\'A FONCTIONNÉ\n');
        print('🔍 Vérifications à faire:');
        print('1. Clé API valide et active');
        print('2. API Generative Language activée sur Google Cloud');
        print('3. Connexion internet stable');
        print('4. Quota non dépassé');
        print('\n🔗 Console Google Cloud: https://console.cloud.google.com/');
      }

    } catch (e, stackTrace) {
      print('\n❌ ERREUR GÉNÉRALE:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

