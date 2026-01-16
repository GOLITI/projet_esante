import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asthme_app/domain/entities/user.dart';
import 'package:asthme_app/domain/repositories/auth_repository.dart';
import 'package:asthme_app/data/models/user_model.dart';
import 'package:asthme_app/data/datasources/local_database.dart';

/// Repository d'authentification LOCAL (SQLite sur téléphone)
/// Ne nécessite PAS de backend Flask
class AuthLocalRepository implements AuthRepository {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';

  final SharedPreferences _prefs;
  final LocalDatabase _db;

  AuthLocalRepository(this._prefs) : _db = LocalDatabase.instance;

  /// Hacher le mot de passe (SHA-256)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 LOGIN LOCAL: $email');
      
      // Récupérer l'utilisateur depuis SQLite local
      final db = await _db.database;
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (result.isEmpty) {
        throw Exception('Email non trouvé');
      }

      final userData = result.first;
      final passwordHash = _hashPassword(password);

      if (userData['password_hash'] != passwordHash) {
        throw Exception('Mot de passe incorrect');
      }

      // Créer l'objet User
      final user = UserModel(
        id: userData['id'].toString(),
        email: userData['email'] as String,
        name: userData['username'] as String,
        createdAt: DateTime.parse(userData['created_at'] as String),
      );

      // Sauvegarder dans SharedPreferences
      await _prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
      await _prefs.setBool(_keyIsLoggedIn, true);

      print('✅ LOGIN LOCAL RÉUSSI: ${user.email}');
      return user;
    } catch (e) {
      print('❌ ERREUR LOGIN LOCAL: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    try {
      print('🔵 REGISTER LOCAL: $email');
      
      final db = await _db.database;
      
      // Vérifier si l'email existe déjà
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (existing.isNotEmpty) {
        throw Exception('Cet email est déjà utilisé');
      }

      // Créer l'utilisateur
      final passwordHash = _hashPassword(password);
      final userId = await db.insert('users', {
        'email': email.toLowerCase(),
        'username': name,
        'password_hash': passwordHash,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Créer le profil avec l'âge
      await _db.saveUserProfile(userId, {
        'age': age,
        'gender': 'Non spécifié',
        'bmi': 0.0,
        'smoking': 0,
        'physical_activity': 0,
        'diet_quality': 0,
        'sleep_quality': 0,
        'pollution_exposure': 0,
        'pollen_exposure': 0,
        'dust_exposure': 0,
        'pet_allergy': 0,
        'family_history_asthma': 0,
        'history_of_allergies': 0,
        'eczema_history': 0,
        'hay_fever': 0,
        'gastroesophageal_reflux': 0,
        'lung_function_fev1': 0.0,
        'lung_function_fvc': 0.0,
      });

      // Créer l'objet User
      final user = UserModel(
        id: userId.toString(),
        email: email.toLowerCase(),
        name: name,
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans SharedPreferences
      await _prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
      await _prefs.setBool(_keyIsLoggedIn, true);

      print('✅ REGISTER LOCAL RÉUSSI: ${user.email}');
      return user;
    } catch (e) {
      print('❌ ERREUR REGISTER LOCAL: $e');
      throw Exception('Erreur d\'inscription: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_keyCurrentUser);
    await _prefs.setBool(_keyIsLoggedIn, false);
    print('✅ LOGOUT LOCAL');
  }

  @override
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  @override
  Future<User?> getCurrentUser() async {
    final userJson = _prefs.getString(_keyCurrentUser);
    if (userJson == null) return null;

    try {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      print('❌ ERREUR GET CURRENT USER: $e');
      return null;
    }
  }
}
