import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/presentation/screens/home_screen.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_event.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc()..add(ChatStarted()),
      child: MaterialApp(
        title: 'PULSAR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
