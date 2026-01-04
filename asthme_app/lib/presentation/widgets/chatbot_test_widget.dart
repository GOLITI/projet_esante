import 'package:flutter/material.dart';
import 'package:asthme_app/data/datasources/chatbot_test_service.dart';

/// Widget de test pour vérifier la connexion au chatbot
class ChatbotTestWidget extends StatefulWidget {
  const ChatbotTestWidget({super.key});

  @override
  State<ChatbotTestWidget> createState() => _ChatbotTestWidgetState();
}

class _ChatbotTestWidgetState extends State<ChatbotTestWidget> {
  String _result = 'Appuyez sur le bouton pour tester la connexion API';
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _result = '🔄 Test en cours...\nVeuillez patienter...';
      _hasError = false;
    });

    try {
      final testService = ChatbotTestService();
      await testService.testConnection();
      setState(() {
        _result = '✅ Test terminé !\n\nVérifiez la console pour voir quel modèle fonctionne.\n\nMettez à jour api_constants.dart avec le modèle qui fonctionne.';
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Erreur détectée:\n\n$e\n\nVérifiez:\n• Clé API valide\n• API activée sur Google Cloud\n• Connexion internet\n• Quota disponible';
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Chatbot'),
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.bug_report,
              size: 64,
              color: Color(0xFF7C4DFF),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test de connexion API Gemini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasError
                    ? Colors.red.shade100
                    : (_isLoading ? Colors.blue.shade50 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasError
                      ? Colors.red.shade300
                      : (_isLoading ? Colors.blue.shade300 : Colors.grey.shade300),
                  width: 2,
                ),
              ),
              child: Text(
                _result,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _hasError ? Colors.red.shade900 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runTest,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Test en cours...' : 'Lancer le test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Conseil: Ouvrez la console/terminal pour voir les logs détaillés',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

