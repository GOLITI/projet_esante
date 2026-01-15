import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asthme_app/domain/entities/user.dart';
import 'package:asthme_app/domain/repositories/auth_repository.dart';
import 'package:asthme_app/data/models/user_model.dart';

/// Repository d'authentification utilisant l'API backend (PostgreSQL)
class AuthApiRepository implements AuthRepository {
  static const String _baseUrl = 'http://localhost:5000/api';
  static const String _keyCurrentUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';

  final SharedPreferences _prefs;
  final http.Client _client;

  AuthApiRepository(this._prefs, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 API CALL: POST $_baseUrl/user/login');
      final response = await _client.post(
        Uri.parse('$_baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('🔵 API RESPONSE: Status ${response.statusCode}');
      print('🔵 API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final userData = data['user'];
          print('✅ USER DATA RECEIVED: $userData');
          
          final user = UserModel(
            id: userData['id'].toString(),
            email: userData['email'],
            name: userData['name'],
            createdAt: DateTime.parse(userData['created_at']),
          );

          print('✅ USER MODEL CREATED: ${user.email}');

          // Sauvegarder l'utilisateur localement
          final userJson = json.encode(user.toJson());
          print('💾 SAVING TO PREFS: $userJson');
          
          await _prefs.setString(_keyCurrentUser, userJson);
          await _prefs.setBool(_keyIsLoggedIn, true);
          
          print('✅ SAVED TO PREFS SUCCESSFULLY');

          return user;
        } else {
          print('❌ API ERROR: ${data['error']}');
          throw Exception(data['error'] ?? 'Erreur de connexion');
        }
      } else {
        final data = json.decode(response.body);
        print('❌ HTTP ERROR ${response.statusCode}: ${data['error']}');
        throw Exception(data['error'] ?? 'Email ou mot de passe incorrect');
      }
    } catch (e) {
      print('❌ EXCEPTION IN LOGIN: $e');
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
      final response = await _client.post(
        Uri.parse('$_baseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final userData = data['user'];
          final user = UserModel(
            id: userData['id'].toString(),
            email: userData['email'],
            name: userData['name'],
            createdAt: DateTime.parse(userData['created_at']),
          );

          // Sauvegarder l'utilisateur localement
          await _prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
          await _prefs.setBool(_keyIsLoggedIn, true);

          return user;
        } else {
          throw Exception(data['error'] ?? 'Erreur d\'inscription');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Erreur lors de l\'inscription');
      }
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
