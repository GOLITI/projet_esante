import 'package:flutter/material.dart';
import 'package:asthme_app/presentation/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8E2DE2), // Rich Purple
              Color(0xFF4A00E0), // Deep Blue/Purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo and Title
              Column(
                children: [
                  // Logo placeholder or asset
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/icons/logo.jpeg',
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Icon(
                            Icons.local_hospital,
                            size: 60,
                            color: Color(0xFF4A00E0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PULSAR',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              // Welcome Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Text(
                      'Bienvenue sur PULSAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Votre assistant intelligent pour la gestion de l\'asthme',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Cards
              _buildCard(Icons.psychology_outlined, Colors.purple),
              const SizedBox(height: 16),
              _buildCard(Icons.monitor_heart_outlined, Colors.teal),
              const SizedBox(height: 16),
              _buildCard(Icons.shield_outlined, Colors.pink),
              const Spacer(flex: 2),
              // Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A00E0),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Commencer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Footer
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Protégez votre santé respiratoire avec l\'intelligence artificielle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 32,
      ),
    );
  }
}
