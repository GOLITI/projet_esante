import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/domain/repositories/auth_repository.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_event.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_state.dart';

/// BLoC de gestion de l'authentification
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Vérifier le statut d'authentification
    on<AuthCheckRequested>(_onAuthCheckRequested);

    // Gérer la connexion
    on<AuthLoginRequested>(_onAuthLoginRequested);

    // Gérer l'inscription
    on<AuthRegisterRequested>(_onAuthRegisterRequested);

    // Gérer la déconnexion
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  /// Vérifier si l'utilisateur est déjà connecté
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isLoggedIn = await authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  /// Gérer la connexion
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🔵 DEBUT LOGIN: ${event.email}');
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      print('✅ LOGIN SUCCESS: User = ${user.email}');
      emit(AuthAuthenticated(user));
      print('✅ STATE EMITTED: AuthAuthenticated');
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      // Attendre 2 secondes avant de repasser à Unauthenticated pour que l'utilisateur voie l'erreur
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthUnauthenticated());
    }
  }

  /// Gérer l'inscription
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        age: event.age,
        gender: event.gender,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(AuthUnauthenticated());
    }
  }

  /// Gérer la déconnexion
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
