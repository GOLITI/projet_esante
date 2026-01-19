import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/sensor_data.dart';

/// Base de données locale SQLite pour l'application
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('asthme_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrémenté pour forcer la migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recréer la table predictions avec sensor_data_id nullable
      await db.execute('DROP TABLE IF EXISTS predictions');
      
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';
      const realType = 'REAL NOT NULL';
      
      await db.execute('''
      CREATE TABLE predictions (
        id $idType,
        user_id $integerType,
        sensor_data_id INTEGER,
        risk_level $textType,
        risk_probability $realType,
        symptoms $textType,
        timestamp $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Table utilisateurs
    await db.execute('''
    CREATE TABLE users (
      id $idType,
      email $textType,
      username $textType,
      password_hash $textType,
      created_at $textType,
      UNIQUE(email)
    )
    ''');

    // Table historique des capteurs PHYSIQUES
    await db.execute('''
    CREATE TABLE sensor_history (
      id $idType,
      user_id $integerType,
      humidity $realType,
      temperature $realType,
      pm25 $realType,
      respiratory_rate $realType,
      timestamp $textType,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    // Table prédictions
    await db.execute('''
    CREATE TABLE predictions (
      id $idType,
      user_id $integerType,
      sensor_data_id INTEGER,
      risk_level $textType,
      risk_probability $realType,
      symptoms $textType,
      timestamp $textType,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    // Table profil utilisateur (données démographiques)
    await db.execute('''
    CREATE TABLE user_profile (
      id $idType,
      user_id $integerType,
      age $integerType,
      gender $textType,
      bmi $realType,
      smoking $integerType,
      physical_activity $integerType,
      diet_quality $integerType,
      sleep_quality $integerType,
      pollution_exposure $integerType,
      pollen_exposure $integerType,
      dust_exposure $integerType,
      pet_allergy $integerType,
      family_history_asthma $integerType,
      history_of_allergies $integerType,
      eczema_history $integerType,
      hay_fever $integerType,
      gastroesophageal_reflux $integerType,
      lung_function_fev1 $realType,
      lung_function_fvc $realType,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      UNIQUE(user_id)
    )
    ''');

    print('✅ Base de données SQLite créée avec succès');
  }

  // ==================== GESTION DES CAPTEURS ====================

  /// Enregistrer les données de capteurs PHYSIQUES
  Future<int> insertSensorData(int userId, SensorData data) async {
    final db = await instance.database;
    return await db.insert('sensor_history', {
      'user_id': userId,
      'humidity': data.humidity,
      'temperature': data.temperature,
      'pm25': data.pm25,
      'respiratory_rate': data.respiratoryRate,
      'timestamp': data.timestamp.toIso8601String(),
    });
  }

  /// Récupérer l'historique des capteurs
  Future<List<SensorData>> getSensorHistory(int userId, {int limit = 50}) async {
    final db = await instance.database;
    final result = await db.query(
      'sensor_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return result.map((json) => SensorData.fromJson(json)).toList();
  }

  /// Supprimer l'historique ancien (plus de 30 jours)
  Future<int> cleanOldSensorData(int userId) async {
    final db = await instance.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return await db.delete(
      'sensor_history',
      where: 'user_id = ? AND timestamp < ?',
      whereArgs: [userId, thirtyDaysAgo.toIso8601String()],
    );
  }

  // ==================== GESTION DES PRÉDICTIONS ====================

  /// Enregistrer une prédiction
  Future<int> insertPrediction({
    required int userId,
    required int sensorDataId,
    required String riskLevel,
    required double riskProbability,
    required String symptoms,
  }) async {
    final db = await instance.database;
    return await db.insert('predictions', {
      'user_id': userId,
      'sensor_data_id': sensorDataId,
      'risk_level': riskLevel,
      'risk_probability': riskProbability,
      'symptoms': symptoms,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Récupérer l'historique des prédictions
  Future<List<Map<String, dynamic>>> getPredictionHistory(int userId, {int limit = 20}) async {
    final db = await instance.database;
    return await db.query(
      'predictions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ==================== GESTION DU PROFIL ====================

  /// Sauvegarder/Mettre à jour le profil utilisateur
  Future<void> saveUserProfile(int userId, Map<String, dynamic> profile) async {
    final db = await instance.database;
    
    final existing = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    profile['user_id'] = userId;

    if (existing.isEmpty) {
      await db.insert('user_profile', profile);
    } else {
      await db.update(
        'user_profile',
        profile,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  /// Récupérer le profil utilisateur
  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // ==================== STATISTIQUES ====================

  /// Obtenir les statistiques de qualité de l'air
  Future<Map<String, double>> getAirQualityStats(int userId, {int days = 7}) async {
    final db = await instance.database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT 
        AVG(humidity) as avg_humidity,
        AVG(pm25) as avg_pm25,
        AVG(aqi) as avg_aqi,
        MAX(pm25) as max_pm25,
        MAX(aqi) as max_aqi
      FROM sensor_history
      WHERE user_id = ? AND timestamp >= ?
    ''', [userId, startDate.toIso8601String()]);

    if (result.isEmpty) return {};
    
    return {
      'avg_humidity': result[0]['avg_humidity'] as double? ?? 0.0,
      'avg_pm25': result[0]['avg_pm25'] as double? ?? 0.0,
      'avg_aqi': result[0]['avg_aqi'] as double? ?? 0.0,
      'max_pm25': result[0]['max_pm25'] as double? ?? 0.0,
      'max_aqi': result[0]['max_aqi'] as double? ?? 0.0,
    };
  }

  /// Obtenir le nombre de prédictions à risque
  Future<Map<String, int>> getRiskStats(int userId, {int days = 30}) async {
    final db = await instance.database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT 
        risk_level,
        COUNT(*) as count
      FROM predictions
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY risk_level
    ''', [userId, startDate.toIso8601String()]);

    final stats = <String, int>{};
    for (var row in result) {
      stats[row['risk_level'] as String] = row['count'] as int;
    }
    
    return stats;
  }

  // ==================== MAINTENANCE ====================

  /// Fermer la base de données
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  /// Supprimer la base de données (pour debug)
  Future deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asthme_app.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('🗑️ Base de données supprimée');
  }
}
