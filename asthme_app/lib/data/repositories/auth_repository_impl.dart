import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asthme_app/domain/entities/user.dart';
import 'package:asthme_app/domain/repositories/auth_repository.dart';
import 'package:asthme_app/data/models/user_model.dart';

/// Implémentation locale du repository d'authentification
/// Utilise SharedPreferences et stockage local (SQLite-like)
class AuthRepositoryImpl implements AuthRepository {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyUsers = 'users';
  static const String _keyIsLoggedIn = 'is_logged_in';

  final SharedPreferences _prefs;

  AuthRepositoryImpl(this._prefs);

  /// Hash du mot de passe avec SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Générer un ID unique simple
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Récupérer tous les utilisateurs enregistrés
  Future<List<UserModel>> _getUsers() async {
    final usersJson = _prefs.getString(_keyUsers);
    if (usersJson == null) return [];

    final List<dynamic> usersList = json.decode(usersJson);
    return usersList.map((user) => UserModel.fromJson(user)).toList();
  }

  /// Sauvegarder tous les utilisateurs
  Future<void> _saveUsers(List<UserModel> users) async {
    final usersJson = json.encode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(_keyUsers, usersJson);
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      // Récupérer tous les utilisateurs
      final users = await _getUsers();

      // Hash du mot de passe entré
      final hashedPassword = _hashPassword(password);

      // Chercher l'utilisateur avec l'email et mot de passe correspondants
      final user = users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            _hashPassword(password) == hashedPassword,
        orElse: () => throw Exception('Email ou mot de passe incorrect'),
      );

      // Sauvegarder l'utilisateur actuel
      await _prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
      await _prefs.setBool(_keyIsLoggedIn, true);

      return user;
    } catch (e) {
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Récupérer tous les utilisateurs
      final users = await _getUsers();

      // Vérifier si l'email existe déjà
      final emailExists = users.any(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );

      if (emailExists) {
        throw Exception('Cet email est déjà utilisé');
      }

      // Créer un nouvel utilisateur
      final newUser = UserModel(
        id: _generateId(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      // Ajouter l'utilisateur avec le mot de passe hashé
      users.add(newUser);

      // Sauvegarder la liste des utilisateurs
      await _saveUsers(users);

      // Sauvegarder aussi le hash du mot de passe (dans la vraie vie, utiliser une table séparée)
      final passwords = _prefs.getString('passwords') ?? '{}';
      final passwordsMap = json.decode(passwords) as Map<String, dynamic>;
      passwordsMap[newUser.id] = _hashPassword(password);
      await _prefs.setString('passwords', json.encode(passwordsMap));

      // Connecter automatiquement l'utilisateur après inscription
      await _prefs.setString(_keyCurrentUser, json.encode(newUser.toJson()));
      await _prefs.setBool(_keyIsLoggedIn, true);

      return newUser;
    } catch (e) {
      throw Exception('Erreur d\'inscription: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_keyCurrentUser);
    await _prefs.setBool(_keyIsLoggedIn, false);
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
      return UserModel.fromJson(json.decode(userJson));
    } catch (e) {
      return null;
    }
  }
}
