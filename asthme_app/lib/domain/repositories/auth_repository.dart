import 'package:asthme_app/domain/entities/user.dart';

/// Interface du repository d'authentification (Clean Architecture)
abstract class AuthRepository {
  /// Connexion avec email et mot de passe
  Future<User> login({
    required String email,
    required String password,
  });

  /// Inscription avec email, mot de passe, nom, âge et genre
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
  });

  /// Déconnexion
  Future<void> logout();

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn();

  /// Récupérer l'utilisateur actuel
  Future<User?> getCurrentUser();
}
