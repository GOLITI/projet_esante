import 'package:equatable/equatable.dart';
import 'package:asthme_app/domain/entities/user.dart';

/// États du BLoC d'authentification
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial
class AuthInitial extends AuthState {}

/// État: Chargement en cours
class AuthLoading extends AuthState {}

/// État: Utilisateur authentifié
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// État: Utilisateur non authentifié
class AuthUnauthenticated extends AuthState {}

/// État: Erreur
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
