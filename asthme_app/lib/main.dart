import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:asthme_app/presentation/screens/dashboard_screen.dart';
import 'package:asthme_app/presentation/screens/login_screen.dart';
import 'package:asthme_app/presentation/screens/register_screen.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_event.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_event.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_state.dart';
import 'package:asthme_app/data/repositories/auth_api_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => AuthApiRepository(prefs),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthApiRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => ChatBloc()..add(ChatStarted()),
          ),
        ],
        child: MaterialApp(
          title: 'PULSAR',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        ),
      ),
    );
  }
}

/// Widget qui gère la navigation selon l'état d'authentification
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Forcer le rebuild à chaque changement d'état
        print('🔄 BUILDWHEN: ${previous.runtimeType} → ${current.runtimeType}');
        return true;
      },
      builder: (context, state) {
        print('🏠 AUTHGATE BUILDER: State = ${state.runtimeType}');
        
        if (state is AuthLoading || state is AuthInitial) {
          print('🏠 AUTHGATE: Showing loading...');
          return Scaffold(
            key: ValueKey('loading_${DateTime.now().millisecondsSinceEpoch}'),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (state is AuthAuthenticated) {
          print('🏠 AUTHGATE: Showing DashboardScreen for ${state.user.email}');
          // Key unique basée sur l'ID utilisateur ET un timestamp pour forcer le rebuild
          return DashboardScreen(
            key: ValueKey('dashboard_${state.user.id}_${DateTime.now().millisecondsSinceEpoch}'),
          );
        }
        
        print('🏠 AUTHGATE: Showing LoginScreen...');
        return LoginScreen(
          key: ValueKey('login_${DateTime.now().millisecondsSinceEpoch}'),
        );
      },
    );
  }
}
