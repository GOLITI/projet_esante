import 'package:equatable/equatable.dart';

/// Événements du BLoC d'authentification
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Événement: Vérifier le statut d'authentification au démarrage
class AuthCheckRequested extends AuthEvent {}

/// Événement: Connexion
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Événement: Inscription
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final int age;
  final String gender;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.age,
    required this.gender,
  });

  @override
  List<Object?> get props => [email, password, name, age, gender];
}

/// Événement: Déconnexion
class AuthLogoutRequested extends AuthEvent {}
