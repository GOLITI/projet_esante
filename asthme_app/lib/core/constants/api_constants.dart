class ApiConstants {
  // ⚠️ IMPORTANT: Les clés API sont maintenant chargées depuis le fichier .env
  // Ne jamais commiter de clés API directement dans le code !
  
  // Google Gemini API Key
  // TODO: Charger depuis .env en utilisant flutter_dotenv
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE', // Valeur par défaut pour le développement
  );

  // Project Information
  static const String projectName = 'projects/33338837024';
  static const String projectNumber = '33338837024';

  // Model Configuration
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
}

