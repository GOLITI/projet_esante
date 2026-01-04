import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE040FB), // Pink/Purple
              Color(0xFF7C4DFF), // Purple
              Color(0xFF40C4FF), // Light Blue
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back Button
                      Align(
                        alignment: Alignment.topLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.grey),
                          label: const Text('Retour', style: TextStyle(color: Colors.grey)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Logo
                      Center(
                        child: Column(
                          children: [
                             Image.asset(
                              'assets/images/icons/logo.jpeg',
                              height: 50,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.local_hospital,
                                size: 50,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'PULSAR',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D0055),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Créer un compte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rejoignez PULSAR dès aujourd\'hui',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      _buildLabel('Nom complet'),
                      const SizedBox(height: 8),
                      _buildTextField(_nameController, 'Jean Dupont', Icons.person_outline),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      _buildTextField(_emailController, 'votre@email.com', Icons.email_outlined),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildLabel('Mot de passe'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _passwordController, 
                        '........', 
                        Icons.lock_outline, 
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onVisibilityChanged: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildLabel('Confirmer le mot de passe'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _confirmPasswordController, 
                        '........', 
                        Icons.lock_outline, 
                        isPassword: true,
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityChanged: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Terms Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Colors.black87, fontSize: 12),
                                children: [
                                  TextSpan(text: 'J\'accepte les '),
                                  TextSpan(
                                    text: 'conditions d\'utilisation',
                                    style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: ' et la '),
                                  TextSpan(
                                    text: 'politique de confidentialité',
                                    style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE040FB), // Pink
                              Color(0xFF40C4FF), // Blue
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Implement registration logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Créer mon compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    IconData icon, 
    {
      bool isPassword = false,
      bool isVisible = false,
      VoidCallback? onVisibilityChanged,
    }
  ) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onVisibilityChanged,
            )
          : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

